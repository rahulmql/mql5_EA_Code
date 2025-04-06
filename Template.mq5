#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"



int OnInit(){

   return(INIT_SUCCEEDED);
}
  
void OnDeinit(const int reason){
   
}

void OnTick(){
   
}



//Make a Buy order
void executeBuy(double entry, double sl=0, double tp=0){
   entry = NormalizeDouble(entry,_Digits);
   trade.Buy(LotSize,NULL,entry,sl,tp,"Buy Order Placed");
}


//Make Sell order
void executeSell(double entry, double sl=0, double tp=0){
   entry = NormalizeDouble(entry,_Digits);
   trade.Sell(LotSize,NULL,entry,sl,tp,"Sell Order Placed");
}

//make a SL for long position, low of last n candle
double slBuy_LastNCandle(int candleCount)
  {
   double lowPrice[];
   CopyLow(_Symbol,Timeframe,0,candleCount,lowPrice);
   int lowPriceIndex = ArrayMinimum(lowPrice);
   double sl = lowPrice[lowPriceIndex];
   sl = NormalizeDouble(sl,_Digits);
   return sl;
  }

//Make SL for Short Postion, High of last N candle
double slSell_LastNCandle(int candleCount)
  {
   double highPrice[];
   CopyHigh(_Symbol,Timeframe,0,candleCount,highPrice);
   int highPriceIndex = ArrayMaximum(highPrice);
   double sl = highPrice[highPriceIndex];
   sl = NormalizeDouble(sl, _Digits);
   return sl;
  }
  
  
//make a SL for long position, low of last n candle
double lowOfLastNCandle(int candleCount, ENUM_TIMEFRAMES timeframe)
  {
   double lowPrice[];
   CopyLow(_Symbol,timeframe,0,candleCount,lowPrice);
   int lowPriceIndex = ArrayMinimum(lowPrice);
   double low = lowPrice[lowPriceIndex];
   low = NormalizeDouble(low,_Digits);
   return low;
  }

//Make SL for Short Postion, High of last N candle
double highOfLastNCandle(int candleCount, ENUM_TIMEFRAMES timeframe)
  {
   double highPrice[];
   CopyHigh(_Symbol,timeframe,0,candleCount,highPrice);
   int highPriceIndex = ArrayMaximum(highPrice);
   double high = highPrice[highPriceIndex];
   high = NormalizeDouble(high, _Digits);
   return high;
  }

//Calculate profit 
double calculateProfit(int magicnumber, string symbol) {
	double totalProfit = 0.0;
	// Loop through all open positions
	for(int i = PositionsTotal() - 1; i >= 0; i--) {
		// Get the ticket number of the position
		ulong ticket = PositionGetTicket(i);
		// Select the position by ticket
		if(PositionSelectByTicket(ticket)) {
			// Check if the position matches the specified magic number and symbol
			if((PositionGetInteger(POSITION_MAGIC) == Magic) && (PositionGetString(POSITION_SYMBOL) == symbol)) {
				// Get the profit of the position
				double positionProfit = PositionGetDouble(POSITION_PROFIT);
				double positionSwap = PositionGetDouble(POSITION_SWAP);
				double positionCommission = HistoryDealGetDouble(ticket, DEAL_COMMISSION);
				totalProfit += positionProfit + positionCommission + positionSwap;
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


//Time 
input int StartTimeHour = 1; //Start Hour Time
input int StartTimeMinute = 30; //Start Hour Time
input int EndTimeHour = 10; //Start Hour Time
input int EndTimeMinute = 30; //Start Hour Time

/*
// Convert trading hours to datetime
datetime convertHourAndMinuteToDatetime(int hour, int minute){
    datetime startTime = StringToTime(IntegerToString(Year() + "." + 
    IntegerToString(Month()) + "." + 
    IntegerToString(Day()) + " " + 
    IntegerToString(hour) + ":" + 
    IntegerToString(minute));
    return startTime;
}*/

datetime BrokerTimeToIST(datetime brokerTime){
    datetime serverTime = TimeCurrent(); // Get current server time
    int gmtOffset = TimeGMTOffset();    // Get GMT offset in seconds
    int istOffset = 5 * 3600 + 30 * 60; // IST is GMT+5:30 (in seconds)

    datetime gmtTime = brokerTime - gmtOffset; // Convert server time to GMT
    datetime istTime = gmtTime + istOffset;    // Convert GMT to IST

    Print("Server Time: ", TimeToString(serverTime, TIME_DATE|TIME_SECONDS));
    Print("IST Time: ", TimeToString(istTime, TIME_DATE|TIME_SECONDS));
    return istTime;
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

double GetLastTradedProfit()
{
    double lastProfit = 0.0;

    // Get the total number of deals in history
    int totalDeals = HistoryDealsTotal();

    // Loop through the deals in reverse order (most recent first)
    for (int i = totalDeals - 1; i >= 0; i--)
    {
        // Get the deal ticket
        ulong dealTicket = HistoryDealGetTicket(i);

        // Select the deal by ticket
        if (HistoryDealGetInteger(dealTicket, DEAL_ENTRY) == DEAL_ENTRY_OUT || 
            HistoryDealGetInteger(dealTicket, DEAL_ENTRY) == DEAL_ENTRY_OUT_BY)
        {
            // Get the profit of the deal
            lastProfit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
            break; // Exit the loop after finding the most recent closed deal
        }
    }

    return lastProfit;
}