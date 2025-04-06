#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <trade/trade.mqh>


//Inputs Variable
input int Magic = 112233; //Magic Number
input ENUM_TIMEFRAMES Timeframe = PERIOD_M3;
input double LotSize = 0.01; //Lot Size
//input double SlPoint = 100;
//input double TpPoint = 200;
input string Str3 = " "; //**************************** SMA EMA Setting ****************************
input int PeriodSma = 9; //SMA Period
input int PeriodEma = 9; //EMA Period
/*input double UpBy = 1.3; //Up By (0/1)
input double DownBy = 1.3; //Down By (0/1)
int input FromOpen = 1; //From Open (0/1)
int input FromClose = 0; //From Close (0/1)*/
input string Str = " "; //**************************** SL and TP Ratio Setting ****************************
input double UserSlRatio = 0; //SL :- Low and TP :- SL * Ratio
input double UserTpRatio = 0; //TP :- High and SL :- TP / Ratio
input double UserSlTpRatio = 1.5; //SL and TP Ratio

int barsTotal = iBars(_Symbol,Timeframe);

CTrade trade;
int handleSma;
int handleEma;

double sma_current, sma_previous;
double ema_current, ema_previou;

double finalSl, finalTp;


int OnInit(){
   trade.SetExpertMagicNumber(Magic);
   
   handleSma = iMA(_Symbol,Timeframe,PeriodSma,0,MODE_SMA,PRICE_MEDIAN);
   handleEma = iMA(_Symbol,Timeframe,PeriodEma,0,MODE_EMA,PRICE_CLOSE);
   
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason){
   
}
void OnTick(){

   if(!hasOpenPosition()){
      
   } 
   
   int bars = iBars(_Symbol,Timeframe);
   if(bars != barsTotal){
      barsTotal = bars;
      
      sma_current = getSma(0);
      sma_previous = getSma(1);
      
      ema_current = getEma(0);
      ema_previou = getEma(1);
      
      //Print("Bars Function");
      
      double preOpen = iOpen(_Symbol,Timeframe,1);
      double openPrice = iOpen(_Symbol,Timeframe,0);
      double closePrice = iClose(_Symbol,Timeframe,0);
      
      if(ema_previou < sma_previous && ema_current > sma_current && !hasOpenPosition()){ 
         if(ema_current*1.0015 < openPrice){
            //ClosePosition(_Symbol,Magic);
            
            double sl = SymbolInfoDouble(_Symbol,SYMBOL_BID)*1.01;
            sl= NormalizeDouble(sl,_Digits);
            
            double tp = SymbolInfoDouble(_Symbol,SYMBOL_BID)*0.99;
            tp = NormalizeDouble(tp,_Digits);
            
            double entry = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
            
           executeSell(sl,tp);
           //executeBuy(tp,sl);
         }
      }
      
      Print("---->",preOpen - openPrice, " > ", openPrice * 0.0005);
      
      if(preOpen - openPrice > openPrice*0.005 && !hasOpenPosition()){
         Print("From Second");
         //ClosePosition(_Symbol,Magic);
            double sl = SymbolInfoDouble(_Symbol,SYMBOL_ASK)* 0.99;
            sl= NormalizeDouble(sl,_Digits);
            double tp = SymbolInfoDouble(_Symbol,SYMBOL_ASK)* 1.02;
            tp = NormalizeDouble(tp,_Digits);
            executeBuy(sl,tp);
            //executeSell(tp,sl);
      }
   }
}
//+------------------------------------------------------------------+

//Calculate in %
double calculateInPercentage(double number, double prcnt){
   double value = number * prcnt/100;
   value = number*_Point;
   value = NormalizeDouble(value,_Digits);
   return value;
}

//Check Position opene
bool hasOpenPosition(){
   for(int i = 0; i < PositionsTotal(); i++){
      ulong positionTicket = PositionGetTicket(i);
      if(PositionGetSymbol(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC))
         return true;
   }
   return false;
}

//Get Sma value
double getSma(int startIdx=0){
   double sma[];
   CopyBuffer(handleSma,0,startIdx,1,sma);
   double value = sma[0];
   value = NormalizeDouble(value,_Digits);
   return value;
}

//Get Ema Value
double getEma(int startIdx=0){
   double ema[];
   CopyBuffer(handleEma,0,startIdx,1,ema);
   double value = ema[0];
   value = NormalizeDouble(value,_Digits);
   return value;
}

//Make a Buy order
void executeBuy(double sl=0, double tp=0){
   double entry = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   entry = NormalizeDouble(entry,_Digits);
   trade.Buy(LotSize,NULL,entry,sl,tp,"Buy Order Placed");
}


//Make Sell order
void executeSell(double sl=0, double tp=0){
   double entry = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   entry = NormalizeDouble(entry,_Digits);
   trade.Sell(LotSize,NULL,entry,sl,tp,"Sell Order Placed");
}


// Function to close an opened position
bool ClosePosition(string symbol, int magicNumber = 0) {
	// Iterate through all open positions
	for(int i = PositionsTotal() - 1; i >= 0; i--) {
		// Select the position by index
		if(PositionGetSymbol(i) == symbol) {
			// Check if the magic number matches (if provided)
			if(magicNumber == 0 || PositionGetInteger(POSITION_MAGIC) == magicNumber) {
				// Get the ticket of the position
				ulong positionTicket = PositionGetInteger(POSITION_TICKET);
				// Close the position
				trade.PositionClose(positionTicket);
				// Check if the position was closed successfully
				if(trade.ResultRetcode() == TRADE_RETCODE_DONE) {
					Print("Position closed successfully. Ticket: ", positionTicket);
					return true;
				} else {
					Print("Failed to close position. Ticket: ", positionTicket, " Error: ", trade.ResultRetcode());
					return false;
				}
			}
		}
	}
	Print("No position found for symbol: ", symbol, " and magic number: ", magicNumber);
	return false;
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


double slBuy_LastNCandle(int candleCount)
  {
   double lowPrice[];
   CopyLow(_Symbol,Timeframe,0,candleCount,lowPrice);
   int lowPriceIndex = ArrayMinimum(lowPrice);
   double sl = lowPrice[lowPriceIndex];
   sl = NormalizeDouble(sl,_Digits);
   return sl;
  }