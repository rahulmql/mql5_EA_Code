//+------------------------------------------------------------------+
//|                                                 gold_5_30_am.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <trade/trade.mqh>


//Input variables
input int MagicNumber = 11111;
input ENUM_TIMEFRAMES Timeframe = PERIOD_M15; //Enter Timeframe
input double LotSize =0.1; //Enter Lot Size
//input int TpPoint = 200;
//input int SlPoint = 50;
input int NumberOfLastNCandle = 14; //Enter last N candle For SL
input string Abc ="";//************ Candle Time to Trade on BreakOut ************
input int CandleCloseTimeHour = 5; //Enter Hour
input int CandleCloseTimeMinute = 30; //Enter Minute
input string ABc ="";//************ Last Time to Take Trade Within ************
input int TimeCapHour = 10; //Enter Hour
input int TimeCapMinute = 0; //Enter Minute


//Glogal Variables
CTrade trade;
long CandleCloseTime = (CandleCloseTimeHour * 3600) + (CandleCloseTimeMinute * 60);
long TimeCap = (TimeCapHour * 3600) + (TimeCapMinute * 60);
double candleCloseHigh;
double candleCloseLow;
int barsTotal = iBars(NULL,Timeframe);


//OnInIt Function

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(MagicNumber);
   return(INIT_SUCCEEDED);
  }

//OnDeInit Function

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {



  }

//OnTick Function

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {

   int bars = iBars(NULL,Timeframe);

   if(bars != barsTotal)
     {

      barsTotal = bars;
      
      int candOpenPrev = int(iTime(_Symbol,Timeframe,1));
      int candClosePrev = int (iTime(_Symbol,Timeframe,0));
      int currTime = TimeLocal();
      
      candClosePrev = brokerTimeToLocalTimeCon(candClosePrev);
      //currTime = brokerTimeToLocalTimeCon(currTime);

      MqlDateTime tm = {};
      TimeToStruct(candClosePrev,tm);
      candClosePrev = tm.hour * 3600 + tm.min * 60;
      
      TimeToStruct(currTime,tm);
      currTime = tm.hour * 3600 + tm.min * 60;
      
      Print("Time : ", candClosePrev, " : ", PeriodSeconds(Timeframe));


      if(candClosePrev >= CandleCloseTime && candClosePrev < CandleCloseTime + PeriodSeconds(Timeframe))
        {
         candleCloseHigh = iHigh(_Symbol,Timeframe,1);
         candleCloseLow = iLow(_Symbol,Timeframe,1);
        }
      
      //check position not opened and it within Time resistance
      if(!hasOpenPosition() && currTime >= CandleCloseTime && currTime < TimeCap)
        {
         double op = iOpen(_Symbol,Timeframe,1);
         double clPrice = iClose(_Symbol,Timeframe,1);

         if(clPrice > candleCloseHigh)
           {
            //executeBuy();
            //executeSell();
            //executeBuyOnSell();
            executeSellOnBuy();
           }
         else
            if(clPrice < candleCloseLow)
              {
               //executeSell();
               //executeBuy();
               //executeSellOnBuy();
               executeBuyOnSell();
              }
        }
     }

  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int brokerTimeToLocalTimeCon(int BT)
  {
   int timeDiff = int(TimeCurrent() - TimeLocal());
   int BT_to_LT = BT - timeDiff;
   return BT_to_LT;
  }



//Check, is already position opened by this EA
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


//Make a Buy order
void executeBuy()
  {

   double entry = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   entry = NormalizeDouble(entry,_Digits);

   /*double sl = entry - SlPoint*_Point;
   sl = NormalizeDouble(sl,_Digits);

   double tp = entry + TpPoint*_Point;
   tp = NormalizeDouble(tp,_Digits);
   */
   
   double sl = slBuy_LastNCandle(NumberOfLastNCandle);
   //Make TP for 1:2
   double tp = entry + (entry - sl) * 2;

   trade.Buy(LotSize,NULL,entry,sl,tp,"Buy Order Placed");
  }


//Make Sell order
void executeSell()
  {

   double entry = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   entry = NormalizeDouble(entry,_Digits);

   /*double sl = entry + SlPoint*_Point;
   sl = NormalizeDouble(sl,_Digits);

   double tp = entry - TpPoint*_Point;
   tp = NormalizeDouble(tp, _Digits);
   */
   
   double sl = slSell_LastNCandle(7);
   //Make TP for 1:2
   double tp = entry - (sl - entry) * 2;
   
   trade.Sell(LotSize,NULL,entry,sl,tp,"Sell Order Placed");
  }
  
  //Make a Buy order
void executeBuyOnSell()
  {

   double entry = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   entry = NormalizeDouble(entry,_Digits);

   /*double sl = entry - SlPoint*_Point;
   sl = NormalizeDouble(sl,_Digits);

   double tp = entry + TpPoint*_Point;
   tp = NormalizeDouble(tp,_Digits);
   */
   
   double sl = slBuy_LastNCandle(NumberOfLastNCandle);
   //Make TP for 1:2
   double tp = entry + (entry - sl) * 2;

   //trade.Sell(LotSize,NULL,entry,tp,sl,"Buy Order Placed");
   
   double askPrice = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double bidPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double extraSpread = SymbolInfoDouble(_Symbol,SYMBOL_POINT) * 2;
   
    sl = slSell_LastNCandle(NumberOfLastNCandle);
   //Make TP for 1:2
    tp = entry - (entry - sl) * 2;
    //trade.Sell(LotSize,NULL,entry,tp,sl,"Buy Order Placed");
   
   //tp = tp - (askPrice -bidPrice - extraSpread); 
   trade.Buy(LotSize,NULL,entry,tp,sl,"Buy Order Placed");
  }


//Make Sell order
void executeSellOnBuy()
  {

   double entry = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   entry = NormalizeDouble(entry,_Digits);

   /*double sl = entry + SlPoint*_Point;
   sl = NormalizeDouble(sl,_Digits);

   double tp = entry - TpPoint*_Point;
   tp = NormalizeDouble(tp, _Digits);
   */
   
   double sl = slSell_LastNCandle(7);
   //Make TP for 1:2
   double tp = entry - (sl - entry) * 2;
   
   //trade.Sell(LotSize,NULL,entry,sl,tp,"Sell Order Placed");
   //trade.Buy(LotSize,NULL,entry,tp,sl,"Sell Order Placed");
  }
  
  
  //make a SL for long position, low of last n candle
double slBuy_LastNCandle(int candleCount){
   double lowPrice[];
   CopyLow(_Symbol,Timeframe,0,candleCount,lowPrice);
   int lowPriceIndex = ArrayMinimum(lowPrice);
   double sl = lowPrice[lowPriceIndex];
   sl = NormalizeDouble(sl,_Digits);
   return sl;
}

//Make SL for Short Postion, High of last N candle
double slSell_LastNCandle(int candleCount){
   double highPrice[];
   CopyHigh(_Symbol,Timeframe,0,candleCount,highPrice);
   int highPriceIndex = ArrayMaximum(highPrice);
   double sl = highPrice[highPriceIndex];
   sl = NormalizeDouble(sl, _Digits);
   return sl;
}
//+------------------------------------------------------------------+
