
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
  //the array for several prices
	double myMovingAverageArray1[],myMovingAverageArray2[];
	
	//last 20 candle for calculaion
	//prpoerties of the MA
	int movingAverageDefinition1=iMA(_Symbol,_Period,10,0,MODE_SMA,PRICE_CLOSE);
	int movingAverageDefinition2=iMA(_Symbol,_Period,50,0,MODE_SMA,PRICE_CLOSE);
	
	//sort the price array from the current candle downwards
	ArraySetAsSeries(myMovingAverageArray1,true);
	ArraySetAsSeries(myMovingAverageArray2,true);
	
	//				EA				1Line now,candle,3 candle ,store result
	CopyBuffer(movingAverageDefinition1,0,0,3,myMovingAverageArray1);
	CopyBuffer(movingAverageDefinition2,0,0,3,myMovingAverageArray2);
	
	Comment("  ");
	if(
		(myMovingAverageArray1[0]>myMovingAverageArray2[0])
	&&	(myMovingAverageArray1[1]<myMovingAverageArray2[1])
	)
	{
		Comment("BUY!");
	}
	
	if(
		(myMovingAverageArray1[0]<myMovingAverageArray2[0])
	&&	(myMovingAverageArray1[1]>myMovingAverageArray2[1])
	)
	{
		Comment("SELL!");
	}
	
	
	//calculate for current candle
	//double myMovingAverageValue=myMovingAverageArray1[0];
	//Comment("MA Short Value: ",myMovingAverageValue);
  }
