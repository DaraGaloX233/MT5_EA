//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include<Trade\Trade.mqh>
CTrade trade;
//BUY TRADE AND SELL TRADE

void OnTrade()
  {
   Comment("This is the first EA");
  }
  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   double Ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   double Bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   double Balance=AccountInfoDouble(ACCOUNT_BALANCE);
   double Equity=AccountInfoDouble(ACCOUNT_EQUITY);
   

   if(Equity>= Balance)
      trade.Buy(0.01,NULL,Ask,0,(Ask+100*_Point),NULL);
      trade.Sell(0.01,NULL,Bid,0,(Bid+100*_Point),NULL);
    
      
  }
//+------------------------------------------------------------------+
/*
Buy(const double volume,const string symbol=NULL,double price=0.0,
const double sl=0.0,const double tp=0.0,const string comment="");
*/