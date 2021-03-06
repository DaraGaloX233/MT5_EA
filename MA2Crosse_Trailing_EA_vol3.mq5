//+------------------------------------------------------------------+
//|                                                  My_RSI_EA_1.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
//---
#include <Trade\PositionInfo.mqh> //包含部位的資訊庫
#include <Trade\Trade.mqh>        //包含執行的交易庫
#include <Trade\SymbolInfo.mqh>

CTrade         m_trade;
CPositionInfo  m_position; //獲取持倉信息的結構體
CSymbolInfo    m_symbol;   // symbol info object

/*
CAccountInfo   m_account;                    // account info wrapper
CDealInfo      m_deal;                       // deals object
COrderInfo     m_order;                      // pending orders object
CMoneyFixedMargin *m_money;
*/

//---input parmeter
input int fastEMA = 26;
input int slowEMA = 55;

//--- Input MACD Parametr
input int macdfastEMA = 12;
input int macdslowEMA = 26;
input int macdSMA     = 9;

input string myComment = "";

//--- input parameters

input long    m_magic           = 98681234;      // magic number
input double   Lots              = 0.10;
input ushort   InpStopLoss       = 30;      // StopLoss 50 ticket or 50.0 points)
input ushort   InpTakeProfit     = 30;      // TakeProfit 50 ticket or 50.0 points)

//---


int iMA_fast_handle;     //Fast MA 晝圖用
int iMA_slow_handle;    //slow MA 存儲句柄變量
double iMA_fast_buf[];   //
double iMA_slow_buf[];   //Fast and slow MABuffer

//int macd_handle; //MACD Handle
//double macd_buf[];  // MACD Buffer

//--- indicator buffers
double         DIFBuffer[];
double         DEABuffer[];
double         MacdHistBuffer[];
double         MacdHistBuffer1[];
//---Add other 2 MA
double w = 0, w1 = 0;
double macdfast[1], macdslow[1];


double m_adjusted_point;
double ExtStopLoss      = 0.0;
double ExtTakeProfit    = 0.0;

ENUM_TIMEFRAMES   m_timeframe;

double Fast[];
double Slow[];


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
    {
//---
     if(!m_symbol.Name(Symbol())) // sets symbol name
          return(INIT_FAILED);
     RefreshRates();

     m_trade.SetExpertMagicNumber(m_magic);


     m_timeframe = PERIOD_CURRENT;


//--- tuning for 3 or 5 digits
     int digits_adjust = 1;


//if(m_symbol.Digits() == 3 || m_symbol.Digits() == 5)
//digits_adjust = 10;

     if(m_symbol.Digits() == 2) // 如果商品是1.00 , us30, ustec, xauusd.
          digits_adjust = 100; // SL 200 點 *100 = 20,000/100;

     m_adjusted_point = m_symbol.Point() * digits_adjust;

     ExtStopLoss       = InpStopLoss       * m_adjusted_point;
     ExtTakeProfit     = InpTakeProfit     * m_adjusted_point;


//=========================================================================================================

     ArraySetAsSeries(Fast, true);
     ArraySetAsSeries(Slow, true);
     ArraySetAsSeries(iMA_fast_buf,  true);     //將數組的索引設置為時間序列
     ArraySetAsSeries(iMA_slow_buf,  true);     //將數組的索引設置為時間序列
     iMA_fast_handle = iMA(Symbol(), Period(), fastEMA, 0, MODE_EMA, PRICE_CLOSE);    //獲取指標句柄
     iMA_slow_handle = iMA(Symbol(), Period(), slowEMA, 0, MODE_EMA, PRICE_CLOSE);    //獲取指標句柄

//macd_handle = iMACD(_Symbol, PERIOD_CURRENT, macdfastEMA, macdslowEMA, macdSMA, PRICE_CLOSE);

     if(iMA_fast_handle == INVALID_HANDLE || iMA_slow_handle == INVALID_HANDLE) //|| macd_handle == INVALID_HANDLE)  //檢查指標句柄是否可用
         {
          Print("Failed to get the indicator handle");    //如果句柄沒有獲取到，打印相關報錯信息到日誌文件中
          return (- 1);  //完成報錯處理 ???
         }

     ChartIndicatorAdd(ChartID(), 0, iMA_fast_handle);    //將指標添加到價格圖表中
     ChartIndicatorAdd(ChartID(), 0, iMA_slow_handle);    //將指標添加到價格圖表中
//ChartIndicatorAdd(ChartID(), 0, macd_handle);
//---
     return(INIT_SUCCEEDED);
    }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
    {
//---
     IndicatorRelease(iMA_fast_handle);  //刪除指標句柄並釋放分配給它的存儲空間
     IndicatorRelease(iMA_slow_handle);  //刪除指標句柄並釋放分配給它的存儲空間
//IndicatorRelease(macd_handle);  //刪除指標句柄並釋放分配給它的存儲空間
     ArrayFree(iMA_fast_buf);
     ArrayFree(iMA_slow_buf);
//ArrayFree(macd_buf);

     Comment("");

    }

//+------------------------------------------------------------------+
//|  OnTester // 如果要測試要加此段                                                                |
//+------------------------------------------------------------------+
double OnTester()
    {

     double profit = TesterStatistics(STAT_PROFIT);
     double max_dd = TesterStatistics(STAT_EQUITY_DD);
     double PF     = TesterStatistics(STAT_PROFIT_FACTOR);
     return(PF);
    }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
    {
//--- Copy Data

//iMAGet(iMA_fast_handle, 3, Fast);
//iMAGet(iMA_slow_handle, 3, Slow);

     double closebuf[];
     //--
      MqlRates priceArray[];
     ArraySetAsSeries(priceArray, true);
     int handle_price = CopyRates(Symbol(), Period(), 0, 3, priceArray);
      //---

      
     int err1 = 0, err2 = 0, err3 = 0;  //用於存儲價格圖表處理結果的變量
     err1 = CopyBuffer(iMA_fast_handle, 0, 1, 10, iMA_fast_buf);            //將指標數據拷貝到動態數組，以進一步處理
     err2 = CopyBuffer(iMA_slow_handle, 0, 1, 10, iMA_slow_buf);            //將指標數據拷貝到動態數組，以進一步處理
     err3 = CopyClose(_Symbol, _Period, 0, 4, closebuf);


     if(err1 < 0 || err2 < 0 || err3 < 0)  //如果出錯
         {
          Print("Failed to copy data from  buffer or price ");    //打印相關錯誤信息到日誌文件
          return ; //並退出函數
         }


     double slowMA = iMA_slow_buf[0];
     double fastMA = iMA_fast_buf[0];
     double lastprice = priceArray[0].close;

     double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
     double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);


//--- for visual

     string text = "Fast[0]=" + DoubleToString(fastMA, m_symbol.Digits() + 1) + "\n" +
                   "slow[0]=" + DoubleToString(slowMA, m_symbol.Digits() + 1) + "\n" +
                   "close[0]=" + DoubleToString(closebuf[2], m_symbol.Digits() + 1) + "\n" +
                   "price[1]=" + DoubleToString(priceArray[1].close, m_symbol.Digits() + 1) + "\n" +
                   "price[0]=" + DoubleToString(priceArray[0].close, m_symbol.Digits() + 1) + "\n" +
                   "close[3]=" + DoubleToString(closebuf[3], m_symbol.Digits() + 1);
     Comment(text);



//--- Condition Setting
     bool cond1, cond3, cond5; //cond7;
     bool cond2, cond4, cond6;//, cond6, cond8;
//--- Trend Up Condition
     cond1 = iMA_fast_buf[0] > iMA_slow_buf[0];
     cond3 = iMA_fast_buf[1] < iMA_slow_buf[1];
     cond5 = (closebuf[2] > closebuf[1]) && (closebuf[2] > iMA_fast_buf[0]);
//cond5 = MACDValue1 > 0.1;
//cond7 = macd_buf[0] > macd_buf[1] && macd_buf[1] > macd_buf[2] && macd_buf[2] > macd_buf[3];

//--- Trend Down Condition
     cond2 = iMA_fast_buf[0] < iMA_slow_buf[0];
     cond4 = iMA_fast_buf[1] > iMA_slow_buf[1];
     cond6 = (closebuf[2] < closebuf[1]) && (closebuf[2] < iMA_fast_buf[0]);
//cond6 = MACDValue1 < -0.1;
//cond8 = macd_buf[0] < macd_buf[1] && macd_buf[1] < macd_buf[2] && macd_buf[2] < macd_buf[3];

//==================================================== Entry Long Trade

     if(cond1 && cond3)
         {

          if(m_position.Select(m_symbol.Name()) && m_position.Magic() == m_magic) //如果該商品已開倉
              {

               if(m_position.PositionType() == POSITION_TYPE_SELL)
                    m_trade.PositionClose(m_symbol.Name()); //如果已有多單，就平倉

               if(m_position.PositionType() == POSITION_TYPE_BUY)
                    return; //如已經有空單，就退出

              }


          if(PositionsTotal() == 0)

              {

               mybuyOrder();
              } //Call buyOrder

         }

     if((cond1 && cond5) && PositionsTotal() == 0)

         {

          if(m_position.Select(m_symbol.Name()) && m_position.Magic() == m_magic) //如果該商品已開倉
              {

               if(m_position.PositionType() == POSITION_TYPE_SELL)
                    m_trade.PositionClose(m_symbol.Name()); //如果已有多單，就平倉

               if(m_position.PositionType() == POSITION_TYPE_BUY)
                    return; //如已經有空單，就退出

              }
              else 
              {
              mybuyOrder();
              }

         
         }


//================================================= Entry Short Trade

     if(cond2 && cond4)
         {

          if(m_position.Select(m_symbol.Name()) && m_position.Magic() == m_magic)//如果該商品已開倉
              {
               if(m_position.PositionType() == POSITION_TYPE_BUY)
                    m_trade.PositionClose(m_symbol.Name()); //如果已有空單，就平倉
               if(m_position.PositionType() == POSITION_TYPE_SELL)
                    return; //如已經有多單，就退出

              }

          if(PositionsTotal() == 0)
              {

               mysellOrder();
              } //call Sell Order
         }

     if((cond2 && cond6) && PositionsTotal() == 0)
         {

          if(m_position.Select(m_symbol.Name()) && m_position.Magic() == m_magic) //如果該商品已開倉
              {

               if(m_position.PositionType() == POSITION_TYPE_SELL)
                    m_trade.PositionClose(m_symbol.Name()); //如果已有多單，就平倉

               if(m_position.PositionType() == POSITION_TYPE_BUY)
                    return; //如已經有空單，就退出

              }
              else
              {
              
              mysellOrder();
              }

          
         }


     if(m_position.Select(m_symbol.Name()) && m_position.Magic() == m_magic)
         {

          if(m_position.PositionType() == POSITION_TYPE_BUY)
              {
               CheckTraillingBuyStop(Ask, slowMA);     //buy
               //Print(" Long_Call_Triling");

              }
          if(m_position.PositionType() == POSITION_TYPE_SELL)
              {
               CheckTraillingSellStop(Bid, slowMA);    // sell
               //Print(" Short_Call_Triling");

              }// end if


         }


    }
//===========================================================================

/*
//+------------------------------------------------------------------+
//| Trailing                                                         |
//+------------------------------------------------------------------+
void Trailing()
  {
   if(InpTrailingStop==0)
      return;
   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of open positions
      if(m_position.SelectByIndex(i))
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {

               if(m_position.PriceCurrent()-m_position.PriceOpen()>ExtTrailingStop+ExtTrailingStep)
                  if(m_position.StopLoss()<m_position.PriceCurrent()-(ExtTrailingStop+ExtTrailingStep))
                    {
                     if(!m_trade.PositionModify(m_position.Ticket(),
                        m_symbol.NormalizePrice(m_position.PriceCurrent()-ExtTrailingStop),
                        m_position.TakeProfit()))
                        Print("Modify ",m_position.Ticket(),
                              " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of result: ",m_trade.ResultRetcodeDescription());
                     continue;
                    }
              }
            else
              {
               if(m_position.PriceOpen()-m_position.PriceCurrent()>ExtTrailingStop+ExtTrailingStep)
                  if((m_position.StopLoss()>(m_position.PriceCurrent()+(ExtTrailingStop+ExtTrailingStep))) ||
                     (m_position.StopLoss()==0))
                    {
                     if(!m_trade.PositionModify(m_position.Ticket(),
                        m_symbol.NormalizePrice(m_position.PriceCurrent()+ExtTrailingStop),
                        m_position.TakeProfit()))
                        Print("Modify ",m_position.Ticket(),
                              " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of result: ",m_trade.ResultRetcodeDescription());
                     continue;
                    }
              }

           }
  }
*/

//========================================================= Trailling Stop Buy
void CheckTraillingBuyStop(double Ask, double slowMA)

    {

     for(int i = PositionsTotal() - 1; i >= 0; i--)
         {
          //m_symbol.Name() = PositionGetSymbol(i);

          if(m_symbol.Name(Symbol()))

              {
               //ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
               //double CurrentStopLoss = PositionGetDouble(POSITION_SL);



               // Buy Long , Old StopLoss < new SP Value
               double ssl = slowMA - 4.0;
               if((m_position.StopLoss() < ssl) || (m_position.StopLoss() == 0))
                   {

                    m_trade.PositionModify(m_position.Ticket(), m_symbol.NormalizePrice(slowMA), 0);

                    Print("Modify ", m_position.Ticket(),
                          " Position -> false. Result Retcode: ", m_trade.ResultRetcode(),
                          ", description of result: ", m_trade.ResultRetcodeDescription());
                   }

              }
         }

    }//End============================================================



//========================================================= Trailling Stop Short
void CheckTraillingSellStop(double Bid, double slowMA)

    {
     for(int i = PositionsTotal() - 1; i >= 0; i--)
         {
          //string symbol = PositionGetSymbol(i);
          if(m_symbol.Name(Symbol()))

              {
               ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
               double CurrentStopLoss = PositionGetDouble(POSITION_SL);

               //Sell Short
               //Sell short ,Old StopLoss > new SP Value
               double ssl = slowMA + 4.0;

               if((m_position.StopLoss() > ssl) || (m_position.StopLoss() == 0))
                   {

                    m_trade.PositionModify(m_position.Ticket(), m_symbol.NormalizePrice(slowMA), 0);

                    Print("Modify ", m_position.Ticket(),
                          " Position -> false. Result Retcode: ", m_trade.ResultRetcode(),
                          ", description of result: ", m_trade.ResultRetcodeDescription());
                   }



              }
         }

    }//End============================================================
//-----------------
//+------------------------------------------------------------------+
//| Get value of buffers for the iMA                                 |
//+------------------------------------------------------------------+
bool iMAGet(int handle_iMA, const int count, double  & array[])
    {
//--- reset error code
     ResetLastError();
//--- fill a part of the iMABuffer array with values from the indicator buffer that has 0 index
     if(CopyBuffer(handle_iMA, 0, 1, count, array) != count)
         {
          //--- if the copying fails, tell the error code
          PrintFormat("Failed to copy data from the iMA indicator, error code %d", GetLastError());
          //--- quit with zero result - it means that the indicator is considered as not calculated
          return(false);
         }
     return(true);
    }
//-----------------
void mybuyOrder()
    {

     double ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
     double buy_sl = ask - ExtStopLoss ;
     double buy_tp = ask + ExtTakeProfit ;


     string comment = StringFormat("Buy %s %G lots at %s, SL=%s TP=%s",
                                   _Symbol, Lots,
                                   DoubleToString(ask),
                                   DoubleToString(buy_sl),
                                   DoubleToString(buy_tp));



     if(!m_trade.Buy(Lots, m_symbol.Name(), ask, buy_sl, 0.0, comment))
         {
          //--- 报错信息
          Print("Buy() method failed. Return code=", m_trade.ResultRetcode(),
                ". Code description: ", m_trade.ResultRetcodeDescription());

         }
     else
         {
          Print("Buy() method executed successfully. Return code=", m_trade.ResultRetcode(),
                " (", m_trade.ResultRetcodeDescription(), ")");
         }
    }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void mysellOrder()
    {

     double bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
     double sell_sl = bid + ExtStopLoss;
     double sell_tp = bid - ExtTakeProfit;

     string comment = StringFormat("Sell %s %G lots at %s, SL=%s TP=%s",
                                   _Symbol, Lots,
                                   DoubleToString(bid),
                                   DoubleToString(sell_sl),
                                   DoubleToString(sell_tp));


     if(!m_trade.Sell(Lots, m_symbol.Name(), bid, sell_sl, 0.0, comment))
         {
          //--- 报错信息
          Print("Sell() method failed. Return code=", m_trade.ResultRetcode(),
                ". Code description: ", m_trade.ResultRetcodeDescription());
         }
     else
         {
          Print("Sell() method executed successfully. Return code=", m_trade.ResultRetcode(),
                " (", m_trade.ResultRetcodeDescription(), ")");

         }

    }






//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Refreshes the symbol quotes data                                 |
//+------------------------------------------------------------------+
bool RefreshRates(void)
    {
//--- refresh rates // ReUpdate
     if(!m_symbol.RefreshRates())
         {
          Print("RefreshRates error");
          return(false);
         }
//--- protection against the return value of "zero" //防止返回值= 0 ;

     if(m_symbol.Ask() == 0 || m_symbol.Bid() == 0)
          return(false);
//---
     return(true);
    }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
