//| Expert initialization function                                   |
//+------------------------------------------------------------------+

#include  <trade/trade.mqh>


   // Define parameters
   input double lotSize = 0.1; // Risk management
   input int atrPeriod = 14; // ATR period for dynamic stop-loss/take-profit
   input double riskRewardRatio = 2; // Risk-reward ratio
   input ENUM_TIMEFRAMES higherTFPeriod = PERIOD_M20; // Higher timeframe for trend confirmation
   input  int higherTFMAPeriod = 50; // Higher timeframe SMA period
   int Magic = 111222333;



CTrade trade;
int handlerFastSma;
int handlerRsi;
int handlerAtr;

int OnInit()
  {
  trade.SetExpertMagicNumber(Magic);
  handlerFastSma = iMA(NULL, higherTFPeriod, higherTFMAPeriod, 0, MODE_SMA, PRICE_CLOSE);
  handlerRsi = iRSI(NULL, 0, 14, PRICE_CLOSE);
  handlerAtr = iATR(NULL, 0, atrPeriod);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {

   // Get higher timeframe trend (e.g., 1-hour SMA)
   double higherTFMA = getFastSMAValue();

   // Get order flow imbalance (simplified example using volume delta)
   double volumeDelta = iVolume(NULL, 0, 0) - iVolume(NULL, 0, 1); // Buy volume - Sell volume

   // Get ATR for dynamic stop-loss/take-profit
   double atr = getAtr();

   // Simulated sentiment analysis (replace with actual logic if needed)
   bool isBullishSentiment = SimulateSentiment();

   // Check for buy signal
   if (volumeDelta > 0 && iClose(_Symbol,higherTFPeriod,0) > higherTFMA && isBullishSentiment && !hasOpenPosition())
     {
      double stopLoss = iClose(_Symbol,higherTFPeriod,0) - riskRewardRatio * atr*2;
      double takeProfit = iClose(_Symbol,higherTFPeriod,0) + (atr * 2);
      //trade.Buy(lotSize, NULL, 0, stopLoss, takeProfit);
      //trade.Sell(lotSize, NULL, 0, takeProfit,stopLoss);
     }

   // Check for sell signal
   if (volumeDelta < 0 && iClose(_Symbol,higherTFPeriod,0) < higherTFMA && !isBullishSentiment &&  !hasOpenPosition())
     {
      double stopLoss = iClose(_Symbol,higherTFPeriod,0) + (atr *5);
      double takeProfit = iClose(_Symbol,higherTFPeriod,0) - (riskRewardRatio * atr *3);
      //trade.Sell(lotSize, NULL, 0, stopLoss, takeProfit);
      trade.Buy(lotSize, NULL, 0, takeProfit,stopLoss);
     }
  }
//+------------------------------------------------------------------+
//| Simulated sentiment analysis function                            |
//+------------------------------------------------------------------+
bool SimulateSentiment()
  {
   // Simulate sentiment based on a simple rule (e.g., RSI)
   double rsi = getRsi();
   if (rsi < 30) // Oversold condition (bullish sentiment)
      return true;
   if (rsi > 70) // Overbought condition (bearish sentiment)
      return false;
   return true; // Default to bullish sentiment
  }
//+------------------------------------------------------------------+

//Calculate fast SMA value
double getFastSMAValue(int shift=0,int count=1){
   double sma[];
   CopyBuffer(handlerFastSma,0,shift,count,sma);
   return NormalizeDouble(sma[0],_Digits);
}


double getRsi(){

   double rsi[];
   CopyBuffer(handlerRsi,0,14,1,rsi);
   return NormalizeDouble(rsi[0],_Digits);

}

double getAtr(){

   double atr[];
   CopyBuffer(handlerAtr,0,0,1,atr);
   return NormalizeDouble(atr[0],_Digits);

}


//Check, is already position opened by this EA
bool hasOpenPosition(){

   for(int i=0; i<PositionsTotal(); i++){
      ulong positionTicket = PositionGetTicket(i);
      if(PositionGetSymbol(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC)) return true; 
   }
   return false;
}