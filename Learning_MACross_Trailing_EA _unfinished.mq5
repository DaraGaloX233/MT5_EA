//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#property   copyright "simon software"
#property   link      "https://github.com/DaraGaloX233"
#property   version  "0.1"

#include <Trade\PositionInfo.mqh>//?
#include <Trade\Trade.mqh>//Trade control
#include <Trade\SymbolInfo.mqh>//The thing we trade

CPositionInfo mPosition;//
CTrade        mTrade;   //trade object
CSymbolInfo   mSymbol;

//input parameters
input double InLots=0.1;//Lots,how many u buy
input ushort InTakeProfit=40; //stop profit
input ushort InStopLoss=30;   //stop loss

input ushort InTrailingStop=30;
input ushort InTrailingStep=10;

input int FastMAperiod=26;//FastMA
input int SlowMAperiod=55;//SlowMA
input ulong mMagic=114514;

ulong          mSlippage = 30;              // slippage

double         mAdjustedPoint=0.0;
double         ExtTakeProfit = 0.0;
double         ExtStopLoss   = 0.0;
double         ExtTrailingStop = 0.0;
double         ExtTrailingStep = 0.0;

int handle_MAfast; //storing the handle of the iMA indicator
int handle_MAslow;//storing the handle of the iMA indicator

double Fast[];
double Slow[];

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()//deal with error
///////////////////////////////////Period check
  {
   if(FastMAperiod<=0 || SlowMAperiod<=0)
     {
      Print("Fast or Slow MA cannot be less than 0");
      return(INIT_PARAMETERS_INCORRECT);
     }

   if(FastMAperiod>=SlowMAperiod)
     {
      Print("Fast MA Period cannot larger than Slow MA Period");
      return(INIT_PARAMETERS_INCORRECT);
     }

   if(!mSymbol.name(Symbol()))
      return(INIT_FAILED);
   RefreshRates();

   string err_txt=" ";
   if(CheckVolumeValue(InLots,err_txt))
      Print(err_txt);
   return(INIT_PARAMETERS_INCORRECT);

//////////////////////////////////////////////
   mTrade.SetExpertMagicNumber(mMagic);
/////////////////////////////////////////////

   `if(IsFillingTypeAllowed(SYMBOL_FILLING_FOK))//?
      mTrade.SetTypeFilling(ORDER_FILLING_FOK);
   else
      if(IsFillingTypeAllowed(SYMBOL_FILLING_IOC))//?
         mTrade.SetTypeFilling(ORDER_FILLING_IOC);
      else
         mTrade.SetDeviationInPoints(mSlippage);//?

   int DigitsAdjust=1;//Correct the digit of trade target
   if(mSymbol.Digits()==3 || mSymbol.Digits()==5)
      DigitsAdjust =10;
   if(mSymbol.Digits()==2)
      DigitsAdjust =100;
   mAdjustedPoint=mSymbol.Point()*DigitsAdjust;

   ExtTakeProfit=InTakeProfit*mAdjustedPoint;//Adjust selfset data
   ExtStopLoss  =InStopLoss*mAdjustedPoint;
   ExtTrailingStop=InTrailingStop*mAdjustedPoint;
   ExtTrailingStep=InTrailingStep*mAdjustedPoint;

/////////////creat handle
//can use iMACD
   handle_MAfast=iMA(mSymbol.Name(),Period(),FastMAperiod,0,MODE_SMA,PRICE_CLOSE);
   handle_MAslow=iMA(mSymbol.Name(),Period(),SlowMAperiod,0,MODE_SMA,PRICE_CLOSE);
   if(handle_MAfast==INVALID_HANDLE||handle_MAslow==INVALID_HANDLE)
      PrintFormat("Fail to creat hadle",
                  mSymbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
   return(INIT_FAILED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ChartIndicatorAdd(ChartID(),0,handle_MAfast);//add indicator into the chart
ChartIndicatorAdd(ChartID(),0,handle_MAslow);
return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+-----------------------------------------------------------------
void OnDeinit(const int reason)
  {
  }
//+------------------------------------------------------------------+

void OnTick()
{
	static datetime PrevBars=0;
	datetime time0=iTime(0);//now type now time
	return;
	PrevBars = time0;
	
	ArraySetAsSeries(Fast,true);//Fast[]
	ArraySetAsSeries(Slow,true);//Slow[]
	iMAGet(handle_MAfast,2,Fast);//?
	iMAGet(handle_MAslow,2,Slow);//?
	
	string text="Fast[1]="+DoubleToString(Fast[1]),mSymbol.Digits()+1)	+"\n"+
					"Fast[0]"=+DoubleToString(Fast[0]),mSymbol.Digits()+1)	+"\n"+
					"Slow[1]"=+DoubleToString(Slow[1]),mSymbol.Digits()+1)	+"\n"+
					"Slow[0]"=+DoubleToString(Slow[0]),mSymbol.Digits()+1);
		Comment(text);
		
//Calculate Position
		int CountBuy=0;
		int CountSell=0;
			CalculatePosition(CountBuy,CountSell);
			
//Trend Up Long
	if((Slow[1]>Fast[1]&&Slow[0]<Fast[0])||Slow[0]<Fast[0])
	if(CountSell>0)
	ClosePosition(POSITION_TYPE_BUY);
		
//Trend Down Short
	if((Slow[1]<Fast[1]&&Slow[0]>Fast[0]||Slow[0]>Fast[0])
	if(CountBuy>0)
	ClosePosition(POSITION_TYPE_SELL);
/////////////////////////////////////////////////////////////////////
	if(CountBuy==0 && CountSell==0)
	{
		
	
	
	
	
	}
}