//+------------------------------------------------------------------+
//|                                                EURUSD MTF AI.mq5 |
//|                                        Gamuchirai Zororo Ndawana |
//|                          https://www.mql5.com/en/gamuchiraindawa |
//+------------------------------------------------------------------+
#property copyright "Gamuchirai Zororo Ndawana"
#property link      "https://www.mql5.com/en/gamuchiraindawa"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Load the ONNX resources                                          |
//+------------------------------------------------------------------+
#resource "\\Files\\EURUSD MN1 AI.onnx" as const uchar onnx_buffer[];

//+-------------------------------------------------------------------+
//| Define our customs                                                |
//+-------------------------------------------------------------------+
enum close_type
  {
   MA_CLOSE = 0, // Moving Averages Close
   AI_CLOSE = 1  // AI Auto Close
  };

//+------------------------------------------------------------------+
//| User inputs                                                      |
//+------------------------------------------------------------------+
input close_type user_close_type = AI_CLOSE; // How should we close our positions?

//+------------------------------------------------------------------+
//| Libraries we need                                                |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
CTrade Trade;

//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
long    onnx_model;
vectorf model_input  = vectorf::Zeros(1);
vectorf model_output = vectorf::Zeros(1);
double  bid,ask;
int     ma_hanlder;
double  ma_buffer[];
int     bb_hanlder;
double  bb_mid_buffer[];
double  bb_high_buffer[];
double  bb_low_buffer[];
int     rsi_hanlder;
double  rsi_buffer[];
int     system_state = 0,model_state=0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- Load our ONNX function
   if(!load_onnx_model())
     {
      return(INIT_FAILED);
     }

//--- Load our technical indicators
   bb_hanlder  = iBands("EURUSD",PERIOD_D1,30,0,1,PRICE_CLOSE);
   rsi_hanlder = iRSI("EURUSD",PERIOD_D1,14,PRICE_CLOSE);
   ma_hanlder  = iMA("EURUSD",PERIOD_D1,20,0,MODE_EMA,PRICE_CLOSE);

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- Release the resources we don't need
   release_resources();

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- Update market data
   update_market_data();

//--- Fetch a prediction from our model
   model_predict();

//--- Display stats
   display_stats();

//--- Find a position
   if(PositionsTotal() == 0)
     {
      if(model_state == 1)
         check_bullish_setup();
      else
         if(model_state == -1)
            check_bearish_setup();
     }

//--- Manage the position we have
   else
     {
      //--- How should we close our positions?
      if(user_close_type == MA_CLOSE)
        {
         ma_close_positions();
        }

      else
        {
         ai_close_positions();
        }

     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Close whenever our AI detects a reversal                         |
//+------------------------------------------------------------------+
void ai_close_positions(void)
  {
   if(system_state != model_state)
     {
      Alert("Reversal detected by our AI system,closing open positions");
      Trade.PositionClose("EURUSD");
     }
  }


//+------------------------------------------------------------------+
//| Close whenever price reverses the moving average                 |
//+------------------------------------------------------------------+
void ma_close_positions(void)
  {
//--- Is our buy position possibly weakening?
   if(system_state == 1)
     {
      if(iClose("EURUSD",PERIOD_D1,0) < ma_buffer[0])
         Trade.PositionClose("EURUSD");
     }
//--- Is our sell position possibly weakening?
   if(system_state == -1)
     {
      if(iClose("EURUSD",PERIOD_D1,0) > ma_buffer[0])
         Trade.PositionClose("EURUSD");
     }
  }

//+------------------------------------------------------------------+
//| Check bearish setup                                              |
//+------------------------------------------------------------------+
void check_bearish_setup(void)
  {
   if(iClose("EURUSD",PERIOD_D1,0) < bb_low_buffer[0])
     {
      if(50 > rsi_buffer[0])
        {
         if(iClose("EURUSD",PERIOD_D1,0) < ma_buffer[0])
           {
            Trade.Sell(0.3,"EURUSD",bid,0,0,"EURUSD MTF AI");
            system_state = -1;
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Check bullish setup                                              |
//+------------------------------------------------------------------+
void check_bullish_setup(void)
  {
   if(iClose("EURUSD",PERIOD_D1,0) > bb_high_buffer[0])
     {
      if(50 < rsi_buffer[0])
        {
         if(iClose("EURUSD",PERIOD_D1,0) > ma_buffer[0])
           {
            Trade.Buy(0.3,"EURUSD",ask,0,0,"EURUSD MTF AI");
            system_state = 1;
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Display account stats                                            |
//+------------------------------------------------------------------+
void display_stats(void)
  {
   Comment("Forecast: ",model_output[0]);
  }

//+------------------------------------------------------------------+
//| Fetch a prediction from our model                                |
//+------------------------------------------------------------------+
void model_predict(void)
  {
//--- Get inputs
   model_input.CopyRates("EURUSD",PERIOD_MN1,COPY_RATES_CLOSE,0,1);
//--- Fetch a prediction from our model
   OnnxRun(onnx_model,ONNX_DEFAULT,model_input,model_output);
//--- Store the model's prediction as a flag
   if(model_output[0] > model_input[0])
     {
      model_state = -1;
     }
   else
      if(model_output[0] < model_input[0])
        {
         model_state = 1;
        }
  }


//+------------------------------------------------------------------+
//| Release the resources we don't need                              |
//+------------------------------------------------------------------+
void release_resources(void)
  {
   OnnxRelease(onnx_model);
   IndicatorRelease(ma_hanlder);
   IndicatorRelease(rsi_hanlder);
   IndicatorRelease(bb_hanlder);
   ExpertRemove();
  }

//+------------------------------------------------------------------+
//| Update our market data                                           |
//+------------------------------------------------------------------+
void update_market_data(void)
  {
//--- Update all our technical data
   bid = SymbolInfoDouble("EURUSD",SYMBOL_BID);
   ask = SymbolInfoDouble("EURUSD",SYMBOL_ASK);
   CopyBuffer(ma_hanlder,0,0,1,ma_buffer);
   CopyBuffer(rsi_hanlder,0,0,1,rsi_buffer);
   CopyBuffer(bb_hanlder,0,0,1,bb_mid_buffer);
   CopyBuffer(bb_hanlder,1,0,1,bb_high_buffer);
   CopyBuffer(bb_hanlder,2,0,1,bb_low_buffer);
  }

//+------------------------------------------------------------------+
//| Load our ONNX model                                              |
//+------------------------------------------------------------------+
bool load_onnx_model(void)
  {
//--- Create the ONNX model from our buffer
   onnx_model = OnnxCreateFromBuffer(onnx_buffer,ONNX_DEFAULT);

//--- Validate the model
   if(onnx_model == INVALID_HANDLE)
     {
      //--- Give feedback
      Comment("Failed to create the ONNX model");
      //--- We failed to create the model
      return(false);
     }

//--- Specify the I/O shapes
   ulong input_shape[] = {1,1};
   ulong output_shape[] = {1,1};

//--- Validate the I/O shapes
   if(!(OnnxSetInputShape(onnx_model,0,input_shape)) || !(OnnxSetOutputShape(onnx_model,0,output_shape)))
     {
      //--- Give feedback
      Comment("We failed to define the correct input shapes");

      //--- We failed to define the correct I/O shape
      return(false);
     }

   return(true);
  }
//+------------------------------------------------------------------+
