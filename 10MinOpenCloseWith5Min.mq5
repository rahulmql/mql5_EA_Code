#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <trade/trade.mqh>

input int Magic = 6587;
input double LotSize = 0.01;
input ENUM_TIMEFRAMES TimeframeLong = PERIOD_M10; 
input ENUM_TIMEFRAMES TimeframeShort = PERIOD_M5;

input int StartTimeHour = 16; //Start Hour Time
input int StartTimeMinute = 0; //Start Minute Time
input int EndTimeHour = 20; //End Hour Time
input int EndTimeMinute = 0; //End Minute Time

//Global Variable
int barsTotal = iBars(_Symbol,TimeframeShort);
CTrade trade;
datetime startTime;
datetime endTime;


int OnInit(){
   trade.SetExpertMagicNumber(Magic);
   return(INIT_SUCCEEDED);
}
  
void OnDeinit(const int reason){
   
}

void OnTick(){
   
   double openAtLong = iOpen(_Symbol,TimeframeLong,1);
   double closeAtLong = iClose(_Symbol,TimeframeLong,1);
   double openCloseDiff = openAtLong - closeAtLong;
   
   double currASK = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double currBid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   
   double temp = getTPInPercentage(currASK,0.8,"long");
   temp = temp - currASK;
   
   datetime brokerTime = TimeCurrent();
   datetime ISTtime = BrokerTimeToIST(brokerTime);
   
   startTime = convertHourAndMinuteToDatetime(StartTimeHour,StartTimeMinute);
   endTime = convertHourAndMinuteToDatetime(EndTimeHour, EndTimeMinute);
   
   int bars = iBars(_Symbol,TimeframeShort);
   if(bars != barsTotal){
      barsTotal = bars;
      
      if(ISTtime > startTime && ISTtime < endTime  && !hasOpenPosition()){
         if(openCloseDiff > 0){
            double sl = getSLInPercentage(currASK,0.3,"long");
            double tp = getTPInPercentage(currASK,0.6,"long");
            
            //sl = getSLInPercentage(currASK,0.3,"short");
            //tp = getTPInPercentage(currASK,0.5,"short");
            
           executeBuy(currASK,sl,tp);
            //executeSell(currBid,sl,tp);
         }
         else{
            double sl = getSLInPercentage(currASK,0.6,"long");
            double tp = getTPInPercentage(currASK,0.9,"long");
            
            //sl = getSLInPercentage(currBid,1,"short");
            //tp = getTPInPercentage(currBid,1,"short");
            
           // executeBuy(currBid,sl,tp);
         }
      }
      
   }
   
}


//functions

// Convert trading hours to datetime
datetime convertHourAndMinuteToDatetime(int hour, int minute){
    // Step 2: Get the current date in GMT
    datetime gmtTime = TimeGMT(); // Current GMT time
    datetime gmtDate = gmtTime - (gmtTime % 86400); // Remove time part to get just the date
    
    datetime time = gmtDate + hour*3600 + minute*60;
    return time;
}

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

//Check Position opene
bool hasOpenPosition(){
   for(int i = 0; i < PositionsTotal(); i++){
      ulong positionTicket = PositionGetTicket(i);
      if(PositionGetSymbol(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC))
         return true;
   }
   return false;
}

//make SL points
double getSLInPoints(double entry, int points, string long_or_short){
   if(long_or_short == "long"){
      double sl = entry - points*_Point;
      sl = NormalizeDouble(sl,_Digits);
      return sl;
   }
   else if(long_or_short == "short"){
      double sl = entry + points*_Point;
      sl = NormalizeDouble(sl,_Digits);
      return sl;
   }
   return 0;
}

//make TP in Points
double getTPInPoints(double entry, int points, string long_or_short){
   if(long_or_short == "long"){
      double tp = entry + points*_Point;
      tp = NormalizeDouble(tp,_Digits);
      return tp;
   }
   else if(long_or_short == "short"){
      double tp = entry - points*_Point;
      tp = NormalizeDouble(tp,_Digits);
      return tp;
   }
   return 0;
}

//make SL in Percentage
double getSLInPercentage(double entry, double percentage, string long_or_short){
   if(long_or_short == "long"){
      double sl = entry * (100 - percentage)/100;
      sl = NormalizeDouble(sl,_Digits);
      return sl;
   }
   else if(long_or_short == "short"){
      double sl = entry * (100 + percentage)/100;
      sl = NormalizeDouble(sl,_Digits);
      return sl;
   }
   return 0;
}

//make TP in Percentage
double getTPInPercentage(double entry, double percentage, string long_or_short){
   if(long_or_short == "long"){
      double tp = entry * (100 + percentage)/100;
      tp = NormalizeDouble(tp,_Digits);
      return tp;
   }
   else if(long_or_short == "short"){
      double tp = entry * (100 - percentage)/100;
      tp = NormalizeDouble(tp,_Digits);
      return tp;
   }
   return 0;
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