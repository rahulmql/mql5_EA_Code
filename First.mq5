//+------------------------------------------------------------------+
//|                                                   ZigZag_fvg.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+


#include <trade/trade.mqh>

//Inputs Variable
input int Magic = 112233;
input double LotSize = 0.1;
input int SlPoint = 100;
input int TpPoint = 200;
input int SlCandleCount = 14;

input int Depth = 12;
input int Deviation = 5;
input int Backstep = 3;
input ENUM_TIMEFRAMES Timeframe = PERIOD_M15;



//Global Variable

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double lastHigh = iHigh(_Symbol,Timeframe,Depth-1);
double lastLow = iLow(_Symbol,Timeframe,Depth-1);
double lastHighLow = iOpen(_Symbol,Timeframe,Depth-1) > iClose(_Symbol,Timeframe,Depth-1) ? lastHigh : lastLow;
int barsTotal = iBars(NULL,Timeframe);

double lastZigZag[2];
double previouZigZag[2];
double previousOfPreviouZigZag[2];

//ZigZag handle
int zigzagHandle;

CTrade trade;

struct FVG
  {
   int               barIndex;     // The bar index where FVG is detected
   double            fvgHigh;   // The high of the FVG
   double            fvgLow;    // The low of the FVG
   string            type;     // long or short
   double            fvgRetestPoint;  //Fvg retest point

   datetime          timeStamp; // Detect Time;
   datetime          firstCandleOpenTime;
   int               firsCandle;
   int               lastCandle;
  };

FVG fvgToExecute;
FVG currFvg;

double lastTempZigZag;
double lastTempFvg = 0.00;



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
//Assign magic number to all orders
   trade.SetExpertMagicNumber(Magic);

// Creating the ZigZag indicator handle
   zigzagHandle = iCustom(NULL, 0, "Examples\\ZigZag", Depth, Deviation, Backstep);

   if(zigzagHandle == INVALID_HANDLE)
     {
      Print("Failed to create ZigZag handle. Error: ", GetLastError());
      return(INIT_FAILED);
     }

   Print("ZigZag initialized successfully.");
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
// Release the indicator handle
   if(zigzagHandle != INVALID_HANDLE)
      IndicatorRelease(zigzagHandle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(fvgToExecute.fvgRetestPoint!= lastTempFvg)
     {
      lastTempFvg = fvgToExecute.fvgRetestPoint;
      if(fvgToExecute.type == "long" && fvgToExecute.fvgHigh >= SymbolInfoDouble(_Symbol,SYMBOL_ASK))
        {
         //place Buy Order
         executeBuy();
        }
      if(fvgToExecute.type == "short" && fvgToExecute.fvgLow <= SymbolInfoDouble(_Symbol,SYMBOL_BID))
        {
         //place Sell Order
         //executeSell();
        }
     }

   int bars = iBars(NULL,Timeframe);

//checking for new candle formation and executing logic
   if(bars != barsTotal)
     {
      barsTotal = bars;

      getZigZagAtIndex(lastZigZag,0);
      getZigZagAtIndex(previouZigZag,1);
      getZigZagAtIndex(previousOfPreviouZigZag,2);

      if(lastTempZigZag == previouZigZag[0])
        {
         fvgToExecute = currFvg;
        }

      if(lastTempZigZag != lastZigZag[0])
        {
         lastTempZigZag = lastZigZag[0];
         currFvg = findFvg(lastZigZag,previouZigZag,previousOfPreviouZigZag);
        }

     }
  }
//+------------------------------------------------------------------+

//check Position opened or not
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
//|                                                                  |
//+------------------------------------------------------------------+
FVG findLongFVG(int preZzIdx, int lastZzIdx)
  {
   FVG tempFvg;
   tempFvg.type="";

   int idx=1;
   for(int i = preZzIdx; i>lastZzIdx+1; i--)
     {
      double firstCandleHigh = iHigh(_Symbol,Timeframe,i);
      double thirdCandleLow = iLow(_Symbol,Timeframe,i-2);

      if(firstCandleHigh < thirdCandleLow)
        {
         tempFvg.fvgHigh = NormalizeDouble(thirdCandleLow,_Digits);
         tempFvg.fvgLow = NormalizeDouble(firstCandleHigh,_Digits);
         tempFvg.fvgRetestPoint = NormalizeDouble(thirdCandleLow,_Digits);
         tempFvg.type="long";
         tempFvg.timeStamp = TimeCurrent();
         tempFvg.firstCandleOpenTime = iTime(_Symbol,Timeframe,i);
         return tempFvg;
        }
     }
   return tempFvg;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
FVG findShortFVG(int preZzIdx, int lastZzIdx)
  {
   FVG tempFvg;
   tempFvg.type="";


   int idx = 1;
   for(int i = preZzIdx; i>lastZzIdx+1; i--)
     {
      double firstCandleLow = iLow(_Symbol,Timeframe,i);
      double thirdCandleHigh = iHigh(_Symbol,Timeframe,i-2);

      if(firstCandleLow > thirdCandleHigh)
        {
         tempFvg.fvgHigh = NormalizeDouble(firstCandleLow,_Digits);
         tempFvg.fvgLow = NormalizeDouble(thirdCandleHigh,_Digits);
         tempFvg.fvgRetestPoint = NormalizeDouble(thirdCandleHigh,_Digits);
         tempFvg.type="short";
         tempFvg.timeStamp = TimeCurrent();
         tempFvg.firstCandleOpenTime = iTime(_Symbol,Timeframe,i);
         tempFvg.firsCandle = i;
         tempFvg.lastCandle = i-2;
         return tempFvg;
        }
     }
   return tempFvg;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
FVG findFvg(double &LZ[], double &PZ[], double &PPZ[])
  {

   double lastZigzagValue = LZ[0];
   double previousZigzagValue = PZ[0];
   double previousOfPreviousZigzagValue = PPZ[0];

   int lastZigzagIdx = int(LZ[1]);
   int previousZigzagIdx = int(PZ[1]);
   int previousOfPreviousZigzagIdx = int(PPZ[1]);

   FVG tempFvg;
   tempFvg.type = "";

//check for Long FVG
   if(lastZigzagValue > previousZigzagValue && lastZigzagValue < previousOfPreviousZigzagValue)
     {
      //it finds between HL and LH
      return findLongFVG(previousZigzagIdx,lastZigzagIdx);
     }
   else
      if(lastZigzagValue > previousZigzagValue && lastZigzagValue > previousOfPreviousZigzagValue)
        {
         //it finds between HL and HH
         return findLongFVG(previousZigzagIdx,lastZigzagIdx);
        }

      //check for short FVG
      else
         if(lastZigzagValue < previousZigzagValue && lastZigzagValue > previousOfPreviousZigzagValue)
           {
            //it finds between LH and HL
            return findShortFVG(previousZigzagIdx,lastZigzagIdx);
           }
         else
            if(lastZigzagValue < previousZigzagValue && lastZigzagValue < previousOfPreviousZigzagValue)
              {
               //it finds between LH and LL
               return findShortFVG(previousZigzagIdx,lastZigzagIdx);
              }
   return tempFvg;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void getZigZagAtIndex(double &arr[], int index)
  {
   double zigzagValues[];
   ArraySetAsSeries(zigzagValues,true);

   if(CopyBuffer(zigzagHandle, 0, 0, 50, zigzagValues) < 0)
      Print("Failed to copy ZigZag high points. Error: ", GetLastError());

   int currZigZag = -1;
   for(int i=0; i<50; i++)
     {
      if(zigzagValues[i] != 0)
         currZigZag++;

      if(currZigZag == index)
        {
         arr[0] = NormalizeDouble(zigzagValues[i],_Digits);
         arr[1] = i;
         return;
        }

     }
  }


//Make a Buy order
void executeBuy()
  {

   double entry = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   entry = NormalizeDouble(entry,_Digits);

   double sl = entry - SlPoint*_Point;
   sl = NormalizeDouble(sl,_Digits);

   double tp = entry + TpPoint*_Point;
   tp = NormalizeDouble(tp,_Digits);


//Make SL based on low of last n candle
//  double sl = slBuy_LastNCandle(SlCandleCount);

//Make TP for 1:2
// double tp = entry + (entry - sl) * 2;

   trade.Buy(LotSize,NULL,entry,sl,tp,"Buy Order Placed"+fvgToExecute.fvgHigh);
  }


//Make Sell order
void executeSell()
  {

   double entry = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   entry = NormalizeDouble(entry,_Digits);

   double sl = entry + SlPoint*_Point;
   sl = NormalizeDouble(sl,_Digits);

   double tp = entry - TpPoint*_Point;
   tp = NormalizeDouble(tp, _Digits);


//Make SL based on high of last n candle
// double sl = slSell_LastNCandle(SlCandleCount);

//Make TP for 1:2
//double tp = entry - (sl - entry) * 2;

   trade.Sell(LotSize,NULL,entry,sl,tp,"Sell Order Placed"+fvgToExecute.fvgLow);
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
//+------------------------------------------------------------------+



/*

if(previouZigZag  < lastZigZag)
           {
            if(lastZigZag < previousOfPreviouZigZag)
              {
               Print("LH Val : ",lastZigZag);
              }
            else
              {
               Print("HH Val : ",lastZigZag);
              }
           }
         else
           {
            if(lastZigZag > previousOfPreviouZigZag)
              {
               Print("HL Val : ",lastZigZag);
               if(myFvg.)
              }
            else
              {
               Print("LL  Val : ",lastZigZag);
              }
           }


*/
//+------------------------------------------------------------------+
