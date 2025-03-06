//+------------------------------------------------------------------+
//|                                    Triangular Exchange Rates.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#define  LOOK_BACK 24
#define  RISK_TF PERIOD_M5
#define  ATR_MULTIPLE 1

//+------------------------------------------------------------------+
//| System resources                                                 |
//+------------------------------------------------------------------+
#resource "\\Files\\XAUUSD Trig Model.onnx" as uchar xauusd_model_buffer[]

//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
long    xauusd_model;
int     count = 0;
vectorf xauusd_model_forecast = vectorf::Zeros(1);
int     atr_handler;
double  atr[];

//+------------------------------------------------------------------+
//| Libraries                                                        |
//+------------------------------------------------------------------+
#include  <Trade/Trade.mqh>
CTrade Trade;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   atr_handler = iATR("XAUUSD",RISK_TF,14);
   xauusd_model = OnnxCreateFromBuffer(xauusd_model_buffer,ONNX_DEFAULT);
   
   if(xauusd_model == INVALID_HANDLE)
      {
         Comment("Failed to create ONNX model: ",GetLastError());
         return(INIT_FAILED);
      }
      
    ulong input_shape[] = {1,5};
    ulong output_shape[] = {1,1};
    
    if(!OnnxSetInputShape(xauusd_model,0,input_shape))
      {
         Comment("Failed to specify ONNX model input shape: ",GetLastError());
         return(INIT_FAILED);
      }
      
    if(!OnnxSetOutputShape(xauusd_model,0,output_shape))
      {
         Comment("Failed to specify ONNX model output shape: ",GetLastError());
         return(INIT_FAILED); 
      }
    
    
    Comment("System initialized.");
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   datetime time_stamp = iTime(Symbol(),PERIOD_CURRENT,0);
   static datetime time_past;
   if(time_past != time_stamp)
      {
         time_past = time_stamp;
         
         CopyBuffer(atr_handler,0,0,1,atr);
         
         if(PositionsTotal() == 0)
            {
               find_setup();
               count = 0;
            }
      }
  }
//+------------------------------------------------------------------+


void find_setup(void)
    {
      
      double vol = SymbolInfoDouble("XAGUSD",SYMBOL_VOLUME_MIN);
      
      vectorf model_inputs = vectorf::Zeros(5);
      int i = 1;
      model_inputs[0] = (float) MathSin((iClose("XAUGBP",PERIOD_CURRENT,i) - iClose("XAUGBP",PERIOD_CURRENT,i + LOOK_BACK)) / (iClose("GBPUSD",PERIOD_CURRENT,i) - iClose("GBPUSD",PERIOD_CURRENT,i + LOOK_BACK)));
      model_inputs[1] = (float) MathCos((iClose("XAUUSD",PERIOD_CURRENT,i) - iClose("XAUUSD",PERIOD_CURRENT,i + LOOK_BACK)) / (iClose("GBPUSD",PERIOD_CURRENT,i) - iClose("GBPUSD",PERIOD_CURRENT,i + LOOK_BACK)));
      model_inputs[2] = (float) MathTan((iClose("XAUGBP",PERIOD_CURRENT,i) - iClose("XAUGBP",PERIOD_CURRENT,i + LOOK_BACK)) / (iClose("XAUUSD",PERIOD_CURRENT,i) - iClose("XAUUSD",PERIOD_CURRENT,i + LOOK_BACK)));
      model_inputs[3] = (float) MathSin((iClose("XAUUSD",PERIOD_CURRENT,i) - iClose("XAUUSD",PERIOD_CURRENT,i + LOOK_BACK)) / (iClose("GBPUSD",PERIOD_CURRENT,i) - iClose("GBPUSD",PERIOD_CURRENT,i + LOOK_BACK)));
      model_inputs[4] = (float) MathTan((iClose("XAUUSD",PERIOD_CURRENT,i) - iClose("XAUUSD",PERIOD_CURRENT,i + LOOK_BACK)) / (iClose("XAUGBP",PERIOD_CURRENT,i) - iClose("XAUGBP",PERIOD_CURRENT,i + LOOK_BACK)));
      
     if(!OnnxRun(xauusd_model,ONNX_DEFAULT,model_inputs,xauusd_model_forecast)) Comment("Failed to obtain model forecast: ", GetLastError());
     
     double ask = SymbolInfoDouble("XAGUSD",SYMBOL_ASK);
     double bid = SymbolInfoDouble("XAGUSD",SYMBOL_BID);
     
     if(xauusd_model_forecast[0] > 0)
      {
         Trade.Buy(vol,"XAGUSD",ask,(bid - (atr[0] * ATR_MULTIPLE)),(bid + (atr[0] * ATR_MULTIPLE)));
      }
     
     
     if(xauusd_model_forecast[0] < 0)
      {
         Trade.Sell(vol,"XAGUSD",bid,(ask + (atr[0] * ATR_MULTIPLE)),(ask - (atr[0] * ATR_MULTIPLE)));
      } 
      
     
     else(Comment("Forecast: ",xauusd_model_forecast[0]));
   }