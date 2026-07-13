//+------------------------------------------------------------------+
//|                     PitchforkPro.mq5                              |
//+------------------------------------------------------------------+

#property indicator_chart_window
#property strict
#property indicator_plots 0



#include "Utils/PFP_Constants.mqh"

#include "Core/PFP_Pitchfork.mqh"
#include "Core/PFP_ObjectManager.mqh"
#include "Core/PFP_GeometryData.mqh"
#include "Core/PFP_GeometryEngine.mqh"
#include "Core/PFP_ObjectScanner.mqh"
#include "Core/PFP_PitchforkReader.mqh"
#include "Core/PFP_Renderer.mqh"
#include "Core/PFP_Storage.mqh"
#include "Core/PFP_ReplaceEngine.mqh"
#include "Core/PFP_Manager.mqh"






CPFP_ObjectManager    ObjectManager;

CPFP_GeometryEngine   GeometryEngine;

CPFP_ObjectScanner    Scanner;

CPFP_PitchforkReader  Reader;


CPFP_Renderer         Renderer;

CPFP_Storage          PFPStorage;

CPFP_ReplaceEngine    ReplaceEngine;


CPFP_Manager          PitchforkManager;



CPFP_GeometryData     ActiveGeometry;







//+------------------------------------------------------------------+
//| INIT                                                              |
//+------------------------------------------------------------------+

int OnInit()
{


   Print("Pitchfork Pro MT5 Build 0.5.0 Started");

   // Verify chart permissions
   if(!ChartGetInteger(0,CHART_MODE))
   {
      Print("OnInit : Chart access error");
      return(INIT_FAILED);
   }



   ObjectManager.Init();



   ReplaceEngine.SetEngines(
                            GeometryEngine,
                            Renderer,
                            ObjectManager
                           );




   PitchforkManager.Clear();






   CPFP_Pitchfork Loaded;



   if(PFPStorage.Load(Loaded))
   {


      Print("Saved Pitchfork Loaded");



      PitchforkManager.Set(Loaded);




      if(GeometryEngine.Build(
                              Loaded,
                              ActiveGeometry
                             ))
      {


         Renderer.Draw(
                       Loaded,
                       ActiveGeometry
                      );


      }


   }
   else
   {

      Print("No Saved Pitchfork");

   }





   return(INIT_SUCCEEDED);

}







//+------------------------------------------------------------------+
//| DEINIT                                                            |
//+------------------------------------------------------------------+

void OnDeinit(const int reason)
{


   CPFP_Pitchfork Current;



   if(PitchforkManager.Get(Current))
   {

      Renderer.Clear(Current);

   }




   ObjectManager.Clear();



   Print("Pitchfork Pro Removed");


}








//+------------------------------------------------------------------+
//| CALCULATE                                                         |
//+------------------------------------------------------------------+

int OnCalculate(
                const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]
               )
{

   return(rates_total);

}








//+------------------------------------------------------------------+
//| EVENTS                                                            |
//+------------------------------------------------------------------+

void OnChartEvent(
                  const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam
                 )
{


   if(id!=CHARTEVENT_KEYDOWN)
      return;






//==================================================
// S = Capture + Save + Draw
//==================================================

if(lparam==83)
{


   Print("KEY S");



   CPFP_Pitchfork NewPitchfork;



   Scanner.Scan();



   if(!Reader.FindPitchfork(NewPitchfork))
   {

      Print("No Pitchfork Found");

      return;

   }





   NewPitchfork.SetID(
                      "PFP_STD_001"
                     );



   NewPitchfork.SetDirection(
                             PFP_BULLISH
                            );



   NewPitchfork.SetActive(true);






   if(!GeometryEngine.Build(
                           NewPitchfork,
                           ActiveGeometry
                          ))
   {

      Print("Geometry Failed");

      return;

   }






   Renderer.Draw(
                 NewPitchfork,
                 ActiveGeometry
                );





   PitchforkManager.Set(
                        NewPitchfork
                       );





   if(PFPStorage.Save(NewPitchfork))
   {

      Print("Pitchfork Saved");

   }



}








//==================================================
// R = Replace
//==================================================

if(lparam==82)
{


   Print("KEY R");



   CPFP_Pitchfork Current;



   if(!PitchforkManager.Get(Current))
   {

      Print("No Active Pitchfork");

      return;

   }





   if(ReplaceEngine.Replace(Current))
   {


      PitchforkManager.Set(Current);


      Print("Replace Completed");


   }
   else
   {

      Print("Replace Failed");

   }



}



}