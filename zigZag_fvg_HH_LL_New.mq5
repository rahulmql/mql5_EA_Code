//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link "https://www.mql5.com"
#property version "1.00"#include <trade/trade.mqh>

//Inputs Variable
input int Magic = 112233; //Magic Number
input ENUM_TIMEFRAMES Timeframe = PERIOD_M15;
input double LotSize = 0.1; //Lot Size
input string Str0 = " "; //**************************** Fresh FVG Setting ****************************
input int FreshFvgYesNo = 1; //Yes/No ( 1/0 )
input int AfterNCandle = 0; //Find After N Candle
input string Str = " "; //**************************** SL and TP Ratio Setting ****************************
input double UserSlRatio = 0; //SL :- Low and TP :- SL * Ratio
input double UserTpRatio = 0; //TP :- High and SL :- TP / Ratio
input double UserSlTpRatio = 1.5; //SL and TP Ratio
input string Str2 = " "; //**************************** Zig Zag Setting ****************************
input int Depth = 12; //Depth
input int Deviation = 5; //Deviation
input int Backstep = 3; //Backstep
//Global Variable
double finalSl;
double finalTp;
int barsTotal = iBars(NULL, Timeframe);
double currZigZag[2];
double previousZigZag[2];
double previousOfPreviousZigZag[2];
double currZigZagValue;
double previousZigZagValue;
double previousOfPreviousZigZagValue;
int currZigZagIndex;
int previousZigZagIndex;
int previousOfPreviousZigZagIndex;
//ZigZag handle
int zigzagHandle;
CTrade trade;
struct FVG {
	int barIndex; // The bar index where FVG is detected
	double fvgHigh; // The high of the FVG
	double fvgLow; // The low of the FVG
	string type; // long or short
	double retestPoint; //Fvg retest point
	double low; //previous low
	double high; //previous high
	double lastSwing; //Last swing Point in a Direction
	bool haveFound;
	bool executed;
};
FVG fvgToExecute;
FVG currFvg;
double lastPreZigzagValue = 0;
double lastHigh;
double lastLow;

input int FastPeriod = 9;   //Fast SMA Period
input int SlowPeriod = 12;  //Slow SMA Period
int handleFastSMA;
int handleSlowSMA;

int TotalFvgCount = 0;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
	//Assign magic number to all orders
	trade.SetExpertMagicNumber(Magic);
	// Creating the ZigZag indicator handle
	zigzagHandle = iCustom(NULL, 0, "Examples\\ZigZag", Depth, Deviation, Backstep);
	if(zigzagHandle == INVALID_HANDLE) {
		Print("Failed to create ZigZag handle. Error: ", GetLastError());
		return (INIT_FAILED);
	}
	Print("ZigZag initialized successfully.");
	
	handleFastSMA = iMA(_Symbol,Timeframe,FastPeriod,0,MODE_SMA,PRICE_CLOSE);
   handleSlowSMA = iMA(_Symbol,Timeframe,SlowPeriod,0,MODE_SMA,PRICE_CLOSE);
   
	lastLow = iLow(_Symbol, Timeframe, 0);
	lastHigh = iHigh(_Symbol, Timeframe, 0);
	return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
	// Release the indicator handle
	if(zigzagHandle != INVALID_HANDLE) IndicatorRelease(zigzagHandle);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick(){
	if(lastPreZigzagValue == 0) {
		getZigZagValueAndIndex(previousZigZag, 2);
		lastPreZigzagValue = previousZigZag[0];
		Print("Last Pre ZZ value asigned : ", lastPreZigzagValue);
	}
	if(!fvgToExecute.executed) {
		string fvgType = fvgToExecute.type;
		double fvgRetestPoint = fvgToExecute.retestPoint;
		double askPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
		double bidPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
		double lastSwing = fvgToExecute.lastSwing;
		askPrice = NormalizeDouble(askPrice, _Digits);
		bidPrice = NormalizeDouble(bidPrice, _Digits);
		if(fvgType == "long" && fvgRetestPoint >= askPrice && currZigZagValue > fvgToExecute.fvgLow) {
			//place Buy Order
			calculateSlTp_Buy(askPrice,lastLow, lastHigh);
			executeBuy(askPrice, finalSl, finalTp);
			fvgToExecute.executed = true;
		}
		if(fvgType == "short" && fvgRetestPoint <= bidPrice && currZigZagValue < fvgToExecute.fvgLow) {
			//place Sell Order
			calculateSlTp_Sell(bidPrice, lastLow, lastHigh);
			executeSell(bidPrice, finalSl, finalTp);
			fvgToExecute.executed = true;
		}
	}
	
	int bars = iBars(_Symbol, Timeframe);
	if(bars != barsTotal) {
		barsTotal = bars;
		getZigZagValueAndIndex(currZigZag, 1);
		getZigZagValueAndIndex(previousZigZag, 2);
		getZigZagValueAndIndex(previousOfPreviousZigZag, 3);
		
		currZigZagValue = currZigZag[0];
		previousZigZagValue = previousZigZag[0];
		previousOfPreviousZigZagValue = previousOfPreviousZigZag[0];
		
		currZigZagIndex = int(currZigZag[1]);
		previousZigZagIndex = int(previousZigZag[1]);
		previousOfPreviousZigZagIndex = int(previousOfPreviousZigZag[1]);
		
		if(lastPreZigzagValue != previousZigZagValue) {
			lastPreZigzagValue = previousZigZagValue;
		//	fvgToExecute = currFvg;
			Print("Pre zz changed");  
		}
		
		//find bullish fvg between previous and last zig zag value
		if(currZigZagValue > lastHigh) {
			lastHigh = currZigZagValue;
			lastLow = previousZigZagValue;
			
			Print("Find Bullish FVG");
			
			if(true){
			   fvgToExecute = findLongFVG(previousZigZagIndex,currZigZagIndex);
			   Print("FVG Found", fvgToExecute.retestPoint);
			}
		}
		//find bearish fvg between previous and last zig zag value
		if(currZigZagValue < lastLow) {
			lastLow = currZigZagValue;
			lastHigh = previousZigZagValue;
			
			Print("Find Bearish fvg");
			
			if(true){
			   fvgToExecute = findShortFVG(previousZigZagIndex,currZigZagIndex);
			   Print("FVG Found", fvgToExecute.retestPoint);
			}
		}
		
	}
}
//+------------------------------------------------------------------+
//check Position opened or not
bool hasOpenPosition() {
	for(int i = 0; i < PositionsTotal(); i++) {
		ulong positionTicket = PositionGetTicket(i);
		if(PositionGetSymbol(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC)) return true;
	}
	return false;
}
//Find Low between two index
double findLowBetweenIndex(int startIdx, int count) {
	double lowPrice[];
	CopyLow(_Symbol, Timeframe, startIdx, count, lowPrice);
	int lowPriceIndex = ArrayMinimum(lowPrice);
	return NormalizeDouble(lowPrice[lowPriceIndex], _Digits);
}
//Find high between two index
double findHighBetweenIndex(int startIdx, int count) {
	double highPrice[];
	CopyHigh(_Symbol, Timeframe, startIdx, count, highPrice);
	int highPriceIndex = ArrayMaximum(highPrice);
	return NormalizeDouble(highPrice[highPriceIndex], _Digits);
}
//Get Zig zig value and its index in an array like first-1, second-2 , third-3 ..........
void getZigZagValueAndIndex(double & arr[], int index) {
	double zigzagValues[];
	ArraySetAsSeries(zigzagValues, true);
	if(CopyBuffer(zigzagHandle, 0, 0, 100, zigzagValues) < 0) Print("Failed to copy ZigZag high points. Error: ", GetLastError());
	int zigzagCount = 0;
	for(int i = 0; i < 50; i++) {
		if(zigzagValues[i] != 0) zigzagCount++;
		if(zigzagCount == index) {
			arr[0] = NormalizeDouble(zigzagValues[i], _Digits);
			arr[1] = i;
			return;
		}
	}
}

//find long fvg in uptrend
FVG findLongFVG(int startIdx, int endIdx)
  {
   FVG tempFvg;
   tempFvg.type="";
   tempFvg.haveFound = false;
   tempFvg.executed = true;

   for(int i = startIdx; i>endIdx+1; i--)
     {
      double firstCandleHigh = iHigh(_Symbol,Timeframe,i);
      double thirdCandleLow = iLow(_Symbol,Timeframe,i-2);
      if(firstCandleHigh < thirdCandleLow)
        {
        TotalFvgCount++;
         tempFvg.executed = false;
         tempFvg.haveFound = true;
         tempFvg.fvgHigh = NormalizeDouble(thirdCandleLow,_Digits);
         tempFvg.fvgLow = NormalizeDouble(firstCandleHigh,_Digits);
         tempFvg.retestPoint = NormalizeDouble(thirdCandleLow,_Digits);
         tempFvg.low = previousZigZagValue;
         tempFvg.high = currZigZagValue;
         tempFvg.type="long";
         DrawRectangle("Long FVG",thirdCandleLow,firstCandleHigh,iTime(_Symbol,Timeframe,i),iTime(_Symbol,Timeframe,i-2),clrBlue);
         return tempFvg;
        }
     }
   return tempFvg;
  }

//find short fvg in down trend
FVG findShortFVG(int startIdx, int endIdx)
  {
   FVG tempFvg;
   tempFvg.type="";
   tempFvg.haveFound = false;
   tempFvg.executed = true;

   for(int i = startIdx; i>endIdx+1; i--)
     {
      double firstCandleLow = iLow(_Symbol,Timeframe,i);
      double thirdCandleHigh = iHigh(_Symbol,Timeframe,i-2);
      if(firstCandleLow > thirdCandleHigh)
        {
        TotalFvgCount++;
         tempFvg.executed = false;
         tempFvg.haveFound = true;
         tempFvg.fvgHigh = NormalizeDouble(firstCandleLow,_Digits);
         tempFvg.fvgLow = NormalizeDouble(thirdCandleHigh,_Digits);
         tempFvg.retestPoint = NormalizeDouble(thirdCandleHigh,_Digits);
         tempFvg.low = currZigZagValue;
         tempFvg.high = previousZigZagValue;
         tempFvg.type="short";
         DrawRectangle("Short FVG",firstCandleLow,thirdCandleHigh,iTime(_Symbol,Timeframe,i),iTime(_Symbol,Timeframe,i-2),clrBrown);
         return tempFvg;
        }
     }
   return tempFvg;
  }
//Make a Buy order
void executeBuy(double entry, double sl, double tp) {
	trade.Buy(LotSize, NULL, entry, sl, tp, "Buy Order Placed");
}
//Make Sell order
void executeSell(double entry, double sl, double tp) {
	trade.Sell(LotSize, NULL, entry, sl, tp, "Sell Order Placed");
}
//calculate SL and TP for Long Position
void calculateSlTp_Buy(double entry, double low, double high) {
	double sl = entry - low;
	double tp = high - entry;
	if(UserSlRatio != 0) {
		finalSl = NormalizeDouble(low, _Digits);
		finalTp = NormalizeDouble(entry + sl * UserSlRatio, _Digits);
	} else
	if(UserTpRatio != 0) {
		finalTp = NormalizeDouble(high, _Digits);
		finalSl = NormalizeDouble(entry - tp / UserTpRatio, _Digits);
	} else
	if(UserSlTpRatio != 0) {
		if(tp / sl < UserSlTpRatio) {
			finalSl = NormalizeDouble(entry - tp / UserSlTpRatio, _Digits);
			finalTp = NormalizeDouble(high, _Digits);
		} else {
			finalSl = NormalizeDouble(low, _Digits);
			finalTp = NormalizeDouble(entry + sl * UserSlTpRatio, _Digits);
		}
	}
}
//calculate SL and TP for Short Position
void calculateSlTp_Sell(double entry, double low, double high) {
	double sl = high - entry;
	double tp = entry - low;
	if(UserSlRatio != 0) {
		finalSl = NormalizeDouble(high, _Digits);
		finalTp = NormalizeDouble(entry - sl * UserSlRatio, _Digits);
	} else
	if(UserTpRatio != 0) {
		finalTp = NormalizeDouble(low, _Digits);
		finalSl = NormalizeDouble(entry + tp / UserTpRatio, _Digits);
	} else
	if(UserSlTpRatio != 0) {
		if(tp / sl < UserSlTpRatio) {
			finalSl = NormalizeDouble(entry + tp / UserSlTpRatio, _Digits);
			finalTp = NormalizeDouble(low, _Digits);
		} else {
			finalSl = NormalizeDouble(high, _Digits);
			finalTp = NormalizeDouble(entry - sl * UserSlTpRatio, _Digits);
		}
	}
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawRectangle(string name, double top, double bottom, datetime left, datetime right, color clr) {
	//name = name + TimeToString(TimeCurrent(),TIME_SECONDS);
	name = name + " " + "Pre : " + previousZigZagValue + " " + "Last : " + currZigZagValue + " FVG Count : "+ TotalFvgCount;
	// Create the rectangle object
	if(!ObjectCreate(0, name, OBJ_RECTANGLE, 0, left, top, right, bottom)) {
		Print("Failed to create rectangle: ", GetLastError());
		return;
	}
	// Set the rectangle color
	ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
	// Set the rectangle border width
	ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
	// Make the rectangle visible on all timeframes
	ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
}
