//+------------------------------------------------------------------+
//|                                            PrevDayHLPrice_EA.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//#resource "AdaptiveChannelADX.ex5"

//int h_acadx;
//double acadx1_buffer[], acadx2_buffer[], Close[];
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//---



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




     double last = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_LAST), _Digits);
     double bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
     double ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);



     double dayHigh = 0.0;
     double dayLow = 0.0;
     double wHigh = 0.0;
     double wLow = 0.0;
     double highs[], lows[], whighs[], wlows[]; // 最高和最低价??

//--- 重置上=0
     ResetLastError();
//--- 全日最高最低值

     int highsgot = CopyHigh(Symbol(), PERIOD_D1, 0, 1, highs); //Today
     int whighsgot = CopyHigh(Symbol(), PERIOD_W1, 0, 1, whighs); //ToWeek
     int lowsgot = CopyLow(Symbol(), PERIOD_D1, 0, 1, lows);
     int wlowsgot = CopyLow(Symbol(), PERIOD_W1, 0, 1, wlows); //To Week


//==========================================================//
     string day_highlevel = "PreviousDayHigh";
     string day_lowlevel  = "PreviousDayLow";
     ObjectDelete(0, day_highlevel);
     ObjectDelete(0, day_lowlevel);
     double weekOrday_Highlevel = 0.0;
     double weekOrday_Lowlevel = 0.0;
     
     if(highsgot > 0) // 如果复制成功
     {
          dayHigh = highs[0]; // 日最新高价
          wHigh = whighs[0];


          if (wHigh > dayHigh)
          {
               weekOrday_Highlevel = wHigh;
          }
          else
          {
               weekOrday_Highlevel = dayHigh;
          }
     }

     /*
               //==========================
               if(ObjectFind(0, day_highlevel) < 0) //find Object
               {
                    ObjectCreate(0, day_highlevel, OBJ_HLINE, 0, 0, 0); // Object setting

               }

               ObjectSetDouble(0, day_highlevel, OBJPROP_PRICE, 0, weekOrday_Highlevel);
               ObjectSetInteger(0, day_highlevel, OBJPROP_COLOR, clrYellow);

               //--- PERIOD_M15 和 PERIOD_H1 的可顯視
               //ObjectSetInteger(0, highlevel, OBJPROP_TIMEFRAMES, OBJ_PERIOD_M15 | OBJ_PERIOD_H1);

          }
          else
          {
               Print("Could not get High prices days, Error = ", GetLastError());
          }
          */

//====================

     if(lowsgot > 0) // 如果复制成功
     {
          dayLow = lows[0]; //最新低价
          wLow  = wlows[0];


          if(wLow < dayLow)
          {
               weekOrday_Lowlevel = wLow;
          }
          else
          {
               weekOrday_Lowlevel = dayLow;
          }
     }
     /*
               if(ObjectFind(0, day_lowlevel) < 0) // 找到名lowlevel物件
               {
                    ObjectCreate(0, day_lowlevel, OBJ_HLINE, 0, 0, 0);
               }
               ObjectSetDouble(0, day_lowlevel, OBJPROP_PRICE, 0, weekOrday_Lowlevel);
               ObjectSetInteger(0, day_lowlevel, OBJPROP_COLOR, clrWhite);
          }
          else
          {
               Print("Could not get Low prices days, Error = ", GetLastError());
          }
          */


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

     double HL_Diff_Point = dayHigh - dayLow; // Find HH /LL Diff Points
     double weekHL_Diff_Point = wHigh - wLow; // Find HH /LL Diff Points

     Comment(

          "\n week_High_Price : ", wHigh,
          "\n week_Low_Price : ", wLow,
          "\n day_High_Price : ", dayHigh,
          "\n day_Low_Price : ", dayLow,
          "\n\n lastPrice :", last,
          "\n\n Week HL_Diff =  :", NormalizeDouble(weekHL_Diff_Point, 2),
          "\n HL_Diff =  :", NormalizeDouble(HL_Diff_Point, 2)

     );

     week_fib_level_line (weekOrday_Highlevel, weekOrday_Lowlevel );
} //End Ontick
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|   Draw Week Fibonacci Line
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void week_fib_level_line (double weekOrday_High_level, double weekOrday_Lowlevel)
{

//----
     MqlRates PriceRates[]; // Take mql rates Data

     ArraySetAsSeries(PriceRates, true);
     int ratesData = CopyRates(Symbol(), Period(), 0, Bars(Symbol(), Period()), PriceRates);

     double toWeekOpen = iOpen(_Symbol, PERIOD_W1, 0); // Take ToWeek Open Price = 0
     datetime toWeekOpenTime = iTime(_Symbol, PERIOD_W1, 0); // ToWeekOpen Time = 0
     ObjectDelete(0, "name");
//ObjectDelete(0, "tradeStopsell");


     ObjectCreate
     (
          0,                                       // current chart
          "name",                         // object name
          OBJ_FIBO,                               // object type
          0,                                       // in main window
          toWeekOpenTime,                      // left border candle  100
          weekOrday_High_level,                                     // Trend Lind, Object price , fast MA
          PriceRates[0].time,                       // right border candle 0
          weekOrday_Lowlevel                                     // if trend line , select object price fast MA

     );

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
     ObjectSetInteger(0, "name", OBJPROP_COLOR, clrYellow);
     ObjectSetInteger(0, "name", OBJPROP_RAY_RIGHT, true);
     ObjectSetInteger(0, "name", OBJPROP_WIDTH, 1);
     ObjectGetDouble(0, "name", OBJPROP_PRICE, 0);

//} //End trailling Stop Line &&&

     return;

}// Trade Control func ==============================================&&&&&


//+------------------------------------------------------------------+
