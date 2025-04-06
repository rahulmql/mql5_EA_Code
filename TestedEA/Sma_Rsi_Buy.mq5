//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

#include  <trade/trade.mqh>

// Define parameters
input double LotSize = 0.1; // Risk management: Adjust based on your account size
input int shortMAPeriod = 9; // Short-term moving average
input int longMAPeriod = 21; // Long-term moving average
input int rsiPeriod = 14; // RSI period
input double overbought = 40; // RSI overbought level
input double oversold = 60; // RSI oversold level
input int SlPoint = 220;
input int TpPoint = 250;
input int Magic = 122333;

ENUM_TIMEFRAMES Timeframe = PERIOD_M6;
input int SlCandleCount = 5;



double shortMAHandler;
double longMAHandler;
double rsiHandler;

CTrade trade;


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   shortMAHandler = iMA(NULL,Timeframe,shortMAPeriod, 0, MODE_LWMA, PRICE_WEIGHTED);
   longMAHandler = iMA(NULL,Timeframe,longMAPeriod, 0, MODE_LWMA, PRICE_HIGH);
   rsiHandler = iRSI(NULL, Timeframe, rsiPeriod, PRICE_LOW);
   trade.SetExpertMagicNumber(Magic);

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   return;
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {

// Get moving averages
   double shortMA = getShortMA();
   double longMA = getLongtMA();

// Get RSI
   double rsi = getRSI();

// Check for buy signal
   if(shortMA < longMA && rsi < oversold && !hasOpenPosition())  // Uptrend and oversold
     {
      //if(PositionsTotal() == 0)  // No existing positions
        
        executeBuy();
        
     }
  }
//+------------------------------------------------------------------+


//Calculate fast SMA value
double getShortMA()
  {
   double sma[];
   CopyBuffer(shortMAHandler,0,0,1,sma);
   return NormalizeDouble(sma[0],_Digits);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getLongtMA()
  {
   double sma[];
   CopyBuffer(longMAHandler,0,0,1,sma);
   return NormalizeDouble(sma[0],_Digits);
  }

double getRSI()
  {

// Get the RSI value for the current candle
   double rsiValue[1];
   if(CopyBuffer(rsiHandler, 0, 0, 1, rsiValue) <= 0)
     {
      Print("Failed to copy RSI buffer!");
     }

   return rsiValue[0];
  }
  
void executeBuy(){

   double entry = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   entry = NormalizeDouble(entry,_Digits);

   double sl = entry - SlPoint*_Point;
   sl = NormalizeDouble(sl,_Digits);
   
   double tp = entry + TpPoint*_Point;
   tp = NormalizeDouble(tp,_Digits);

   trade.Buy(LotSize,NULL,entry,sl,tp,"Buy Order Placed");
}
   
  
bool hasOpenPosition()
  {

   for(int i=0; i<PositionsTotal(); i++)
     {
      ulong positionTicket = PositionGetTicket(i);
      if(PositionGetSymbol(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC))
         return true;
     }
   return false;
  }



//+------------------------------------------------------------------+
