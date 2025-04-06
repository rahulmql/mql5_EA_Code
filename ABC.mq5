//| Expert initialization function                                   |
//+------------------------------------------------------------------+

#include  <trade/trade.mqh>


   // Define parameters
   input double lotSize = 0.01; // Risk management
   input int atrPeriod = 14; // ATR period for dynamic stop-loss/take-profit
   input double riskRewardRatio = 2; // Risk-reward ratio
   input ENUM_TIMEFRAMES higherTFPeriod = PERIOD_M5; // Higher timeframe for trend confirmation
   input  int MAPeriod = 14; // Higher timeframe SMA period
   int Magic = 111222333;
   input ENUM_TIMEFRAMES Timeframe = PERIOD_M30;



CTrade trade;
int handlerEma;
int handlerSma;
int handlerRsi;
int handlerAtr;

bool buy_flag = true;
double initialProfit = 8;


int OnInit()
  {
  trade.SetExpertMagicNumber(Magic);
  handlerEma = iMA(NULL, higherTFPeriod, MAPeriod, 0, MODE_EMA, PRICE_CLOSE);
  handlerSma = iMA(NULL, higherTFPeriod, MAPeriod, 0, MODE_SMA, PRICE_CLOSE);
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
   
   if(CalculateProfit(Magic,_Symbol) == 0){
      ClosePosition(_Symbol,Magic);
   }
  
  /* if(CalculateProfit(Magic,_Symbol) > initialProfit || CalculateProfit(Magic,_Symbol) < -10){
      ClosePosition(_Symbol,Magic);
   }
   else if(CalculateProfit(Magic,_Symbol) < initialProfit*-1){
      if(buy_flag){
         trade.Buy(lotSize,NULL,0,0,0);
         buy_flag = false;
      }else{
         trade.Sell(lotSize,NULL,0,0,0);
         buy_flag = true;
      }
      initialProfit += 4;
  }
   */
   // Get order flow imbalance (simplified example using volume delta)
   double volumeDelta = iVolume(NULL, 0, 0) - iVolume(NULL, 0, 1); // Buy volume - Sell volume

   // Get ATR for dynamic stop-loss/take-profit
   double atr = getAtr();
   
   double emaValue = getEma();
   double smaValue = getSma();

   // Simulated sentiment analysis (replace with actual logic if needed)
   bool isBullishSentiment = SimulateSentiment();
   
   
    

   if(!hasOpenPosition()){
      // Check for buy signal
      if(volumeDelta < 0 && emaValue > smaValue && isBullishSentiment){
         trade.Buy(lotSize);
        //trade.Sell(lotSize);
      }
      if(volumeDelta > 0 && emaValue < smaValue && !isBullishSentiment){
         trade.Sell(lotSize);
         //trade.Buy(lotSize);
      }
   }
   
  }
//+------------------------------------------------------------------+
//| Simulated sentiment analysis function                            |
//+------------------------------------------------------------------+
bool SimulateSentiment()
  {
   // Simulate sentiment based on a simple rule (e.g., RSI)
   double rsi = getRsi();
   if (rsi < 40) // Oversold condition (bullish sentiment)
      return true;
   if (rsi > 70) // Overbought condition (bearish sentiment)
      return false;
   return true; // Default to bullish sentiment
  }
//+------------------------------------------------------------------+

//Calculate EMA value
double getEma(int shift=0,int count=1){
   double ema[];
   CopyBuffer(handlerEma,0,shift,count,ema);
   return NormalizeDouble(ema[0],_Digits);
}

//Calculate SMA value
double getSma(int shift=0,int count=1){
   double sma[];
   CopyBuffer(handlerSma,0,shift,count,sma);
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

// Function to calculate profit for all open positions or a specific position
double CalculateProfit(int magicNumber = -1, string symbol = "")
{
    double totalProfit = 0.0;

    // Loop through all open positions
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        // Get the ticket number of the position
        ulong ticket = PositionGetTicket(i);

        // Select the position by ticket
        if (PositionSelectByTicket(ticket))
        {
            // Check if the position matches the specified magic number and symbol
            if ((magicNumber == -1 || PositionGetInteger(POSITION_MAGIC) == magicNumber) &&
                (symbol == "" || PositionGetString(POSITION_SYMBOL) == symbol))
            {
                // Get the profit of the position
                double positionProfit = PositionGetDouble(POSITION_PROFIT);
                totalProfit += positionProfit;
            }
        }
    }

    return totalProfit;
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