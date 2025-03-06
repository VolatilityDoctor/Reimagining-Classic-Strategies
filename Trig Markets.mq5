//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property script_show_inputs

#define LOOK_BACK 24

//--- File name
string file_name = "EURUSD XAGEUR XAGUSD Trigonometric Markets.csv";

//--- Amount of data requested
input int size = 3000;

//+------------------------------------------------------------------+
//| Our script execution                                             |
//+------------------------------------------------------------------+
void OnStart()
  {
//---Write to file
   int file_handle=FileOpen(file_name,FILE_WRITE|FILE_ANSI|FILE_CSV,",");

   for(int i=size;i>=1;i--)
     {
      if(i == size)
        {
         FileWrite(file_handle,"Time","XAUUSD Close","GU Open","GU High","GU Low","GU Close","XG Open","XG High","XG Low","XG Close","XU Open","XU High","XU Low","XU Close","SIN XU^GU","COS XU^GU","TAN XU^GU","SIN XG^GU","TAN XG^GU");
        }

      else
        {
         FileWrite(file_handle,
                   iTime("GBPUSD",PERIOD_CURRENT,i),
                   iClose("XAUUSD",PERIOD_CURRENT,i),
                   iOpen("GBPUSD",PERIOD_CURRENT,i)  - iOpen("GBPUSD",PERIOD_CURRENT,i + LOOK_BACK), 
                   iHigh("GBPUSD",PERIOD_CURRENT,i)  - iHigh("GBPUSD",PERIOD_CURRENT,i + LOOK_BACK),
                   iLow("GBPUSD",PERIOD_CURRENT,i)   - iLow("GBPUSD",PERIOD_CURRENT,i + LOOK_BACK),
                   iClose("GBPUSD",PERIOD_CURRENT,i) - iClose("GBPUSD",PERIOD_CURRENT,i + LOOK_BACK),
                   iOpen("XAUGBP",PERIOD_CURRENT,i)  - iOpen("XAUGBP",PERIOD_CURRENT,i + LOOK_BACK), 
                   iHigh("XAUGBP",PERIOD_CURRENT,i)  - iHigh("XAUGBP",PERIOD_CURRENT,i + LOOK_BACK),
                   iLow("XAUGBP",PERIOD_CURRENT,i)   - iLow("XAUGBP",PERIOD_CURRENT,i + LOOK_BACK),
                   iClose("XAUGBP",PERIOD_CURRENT,i) - iClose("XAUGBP",PERIOD_CURRENT,i + LOOK_BACK),
                   iOpen("XAUUSD",PERIOD_CURRENT,i)  - iOpen("XAUUSD",PERIOD_CURRENT,i + LOOK_BACK),
                   iHigh("XAUUSD",PERIOD_CURRENT,i)  - iHigh("XAUUSD",PERIOD_CURRENT,i + LOOK_BACK),
                   iLow("XAUUSD",PERIOD_CURRENT,i)   - iLow("XAUUSD",PERIOD_CURRENT,i + LOOK_BACK),
                   iClose("XAUUSD",PERIOD_CURRENT,i) - iClose("XAUUSD",PERIOD_CURRENT,i + LOOK_BACK),
                   MathSin((iClose("XAUGBP",PERIOD_CURRENT,i) - iClose("XAUGBP",PERIOD_CURRENT,i + LOOK_BACK)) / (iClose("GBPUSD",PERIOD_CURRENT,i) - iClose("GBPUSD",PERIOD_CURRENT,i + LOOK_BACK))),
                   MathCos((iClose("XAUUSD",PERIOD_CURRENT,i) - iClose("XAUUSD",PERIOD_CURRENT,i + LOOK_BACK)) / (iClose("GBPUSD",PERIOD_CURRENT,i) - iClose("GBPUSD",PERIOD_CURRENT,i + LOOK_BACK))),
                   MathTan((iClose("XAUGBP",PERIOD_CURRENT,i) - iClose("XAUGBP",PERIOD_CURRENT,i + LOOK_BACK)) / (iClose("XAUUSD",PERIOD_CURRENT,i) - iClose("XAUUSD",PERIOD_CURRENT,i + LOOK_BACK))),
                   MathSin((iClose("XAUUSD",PERIOD_CURRENT,i) - iClose("XAUUSD",PERIOD_CURRENT,i + LOOK_BACK)) / (iClose("GBPUSD",PERIOD_CURRENT,i) - iClose("GBPUSD",PERIOD_CURRENT,i + LOOK_BACK))),
                   MathTan((iClose("XAUUSD",PERIOD_CURRENT,i) - iClose("XAUUSD",PERIOD_CURRENT,i + LOOK_BACK)) / (iClose("XAUGBP",PERIOD_CURRENT,i) - iClose("XAUGBP",PERIOD_CURRENT,i + LOOK_BACK)))
                   );
        }
     }
//--- Close the file
   FileClose(file_handle);
  }
//+------------------------------------------------------------------+
