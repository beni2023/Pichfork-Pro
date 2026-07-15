#ifndef PFP_RENDERER_MQH
#define PFP_RENDERER_MQH


#include "../Utils/PFP_Constants.mqh"

#include "PFP_Pitchfork.mqh"
#include "PFP_GeometryData.mqh"


//==================================================
// Render Modes
//==================================================
enum ENUM_PFP_RENDER_MODE
  {
   RENDER_MODE_CREATE_ONLY,      // Only create if not exists
   RENDER_MODE_UPDATE_ONLY,      // Only update if exists
   RENDER_MODE_FULL              // Create or Update as needed
  };


class CPFP_Renderer
{


public:


//==================================================
// Draw - Enhanced with update logic and proper object management
//==================================================

void Draw(
          CPFP_Pitchfork &pf,
          S_PFP_Geometry &geo,
          ENUM_PFP_RENDER_MODE mode = RENDER_MODE_FULL
         )
{


   if(!pf.Validate())
   {

      Print("[Renderer Error] Invalid Pitchfork");

      return;

   }


   string id = pf.ID();


   // Validate geometry data
   if(geo.MedianTime1 == 0 || geo.MedianTime2 == 0)
   {
      Print("[Renderer Error] Invalid geometry data for ID: ", id);
      return;
   }


   color mainColor = pf.GetColor();
   int line_idx = 0;


   // 1. Median Line (Red, Dotted)
   string median_name = GenerateObjectName(id, line_idx++);
   if(mode != RENDER_MODE_UPDATE_ONLY || ObjectExists(median_name))
   {
      DrawTrendLine(
                    median_name,
                    geo.MedianTime1,
                    geo.MedianPrice1,
                    geo.MedianTime2,
                    geo.MedianPrice2,
                    PFP_COLOR_MEDIAN,
                    STYLE_DOT,
                    1,
                    true  // Selectable
                   );
   }


   // 2. Upper Outer Line (Main Color, Solid)
   string upper_name = GenerateObjectName(id, line_idx++);
   if(mode != RENDER_MODE_UPDATE_ONLY || ObjectExists(upper_name))
   {
      DrawTrendLine(
                    upper_name,
                    geo.UpperTime1,
                    geo.UpperPrice1,
                    geo.UpperTime2,
                    geo.UpperPrice2,
                    mainColor,
                    STYLE_SOLID,
                    2,
                    true  // Selectable
                   );
   }


   // 3. Lower Outer Line (Main Color, Solid)
   string lower_name = GenerateObjectName(id, line_idx++);
   if(mode != RENDER_MODE_UPDATE_ONLY || ObjectExists(lower_name))
   {
      DrawTrendLine(
                    lower_name,
                    geo.LowerTime1,
                    geo.LowerPrice1,
                    geo.LowerTime2,
                    geo.LowerPrice2,
                    mainColor,
                    STYLE_SOLID,
                    2,
                    true  // Selectable
                   );
   }


   // 4. Mid Upper Line (Silver, Dashed)
   string mid_upper_name = GenerateObjectName(id, line_idx++);
   if(mode != RENDER_MODE_UPDATE_ONLY || ObjectExists(mid_upper_name))
   {
      DrawTrendLine(
                    mid_upper_name,
                    geo.MidUpperTime1,
                    geo.MidUpperPrice1,
                    geo.MidUpperTime2,
                    geo.MidUpperPrice2,
                    clrSilver,
                    STYLE_DASH,
                    1,
                    false  // Not selectable (helper line)
                   );
   }


   // 5. Mid Lower Line (Silver, Dashed)
   string mid_lower_name = GenerateObjectName(id, line_idx++);
   if(mode != RENDER_MODE_UPDATE_ONLY || ObjectExists(mid_lower_name))
   {
      DrawTrendLine(
                    mid_lower_name,
                    geo.MidLowerTime1,
                    geo.MidLowerPrice1,
                    geo.MidLowerTime2,
                    geo.MidLowerPrice2,
                    clrSilver,
                    STYLE_DASH,
                    1,
                    false  // Not selectable (helper line)
                   );
   }


   // Cleanup orphaned lines (e.g., if switching modes or reducing lines)
   CleanupOrphans(id, line_idx);


   Print("[Renderer] Drawn ", id, " (", line_idx, " lines)");


}


//==================================================
// Clear Pitchfork Objects by ID
//==================================================

void Clear(CPFP_Pitchfork &pf)
{
   string id = pf.ID();
   ClearByID(id);
}


//==================================================
// Clear by String ID
//==================================================

void ClearByID(const string &id)
{
   if(id == "") return;
   
   int removed = 0;
   // Try to remove up to 10 lines (safety limit)
   for(int i = 0; i < 10; i++)
   {
      string name = GenerateObjectName(id, i);
      if(ObjectExists(name))
      {
         if(ObjectDelete(0, name))
           removed++;
      }
      else
      {
         // Stop if we find a gap (assuming sequential numbering)
         break;
      }
   }
   
   if(removed > 0)
      Print("[Renderer] Removed pitchfork ID: ", id, " (", removed, " lines)");
}


//==================================================
// Clear All PFP Objects
//==================================================

void ClearAll()
{
   int total = ObjectsTotal(0, 0, OBJ_TREND);
   int removed = 0;
   
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i, 0, OBJ_TREND);
      if(StringFind(name, PFP_PREFIX) == 0)
      {
         if(ObjectDelete(0, name))
           removed++;
      }
   }
   
   Print("[Renderer] Cleared all ", removed, " objects with prefix: ", PFP_PREFIX);
}


private:


//==================================================
// Generate Unique Object Name
//==================================================

string GenerateObjectName(const string &id, int line_index)
{
   // Format: PFP_<ID>_L<Index>
   // Example: PFP_STD_001_L0
   return StringFormat("%s%s_L%d", PFP_PREFIX, id, line_index);
}


//==================================================
// Check Object Existence
//==================================================

bool ObjectExists(const string &name)
{
   return ObjectFind(0, name) >= 0;
}


//==================================================
// Draw or Update Trend Line
//==================================================

void DrawTrendLine(
                   const string &name,
                   datetime t1,
                   double p1,
                   datetime t2,
                   double p2,
                   color clr,
                   ENUM_LINE_STYLE style,
                   int width,
                   bool selectable
                  )
{
   bool created = false;
   
   // If object doesn't exist, create it
   if(!ObjectExists(name))
   {
      if(!ObjectCreate(0, name, OBJ_TREND, 0, t1, p1, t2, p2))
      {
         Print("[Renderer Error] Failed to create object: ", name, " Error: ", GetLastError());
         return;
      }
      created = true;
   }
   
   // Update properties (works for both new and existing objects)
   // This avoids the need to delete/recreate, preserving user zoom/scroll context
   
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, selectable);
   ObjectSetInteger(0, name, OBJPROP_SELECTED, false);  // Ensure not selected after draw
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, false);    // Visible by default
   ObjectSetInteger(0, name, OBJPROP_BACK, false);      // Draw on top of candles
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, true);  // Extend to right
   
   // Update coordinates if changed (critical for dynamic updates)
   datetime cur_time1 = (datetime)ObjectGetInteger(0, name, OBJPROP_TIME, 0);
   double cur_price1 = ObjectGetDouble(0, name, OBJPROP_PRICE, 0);
   datetime cur_time2 = (datetime)ObjectGetInteger(0, name, OBJPROP_TIME, 1);
   double cur_price2 = ObjectGetDouble(0, name, OBJPROP_PRICE, 1);
   
   if(cur_time1 != t1 || cur_price1 != p1 || cur_time2 != t2 || cur_price2 != p2)
   {
      ObjectSetInteger(0, name, OBJPROP_TIME, 0, t1);
      ObjectSetInteger(0, name, OBJPROP_PRICE, 0, p1);
      ObjectSetInteger(0, name, OBJPROP_TIME, 1, t2);
      ObjectSetInteger(0, name, OBJPROP_PRICE, 1, p2);
   }
}


//==================================================
// Cleanup Orphaned Objects
//==================================================

void CleanupOrphans(const string &id, int expected_lines_count)
{
   // We expect lines 0 to expected_lines_count-1
   // Any line >= expected_lines_count with our prefix and ID should be deleted
   int max_check = expected_lines_count + 5; // Safety buffer
   int removed = 0;
   
   for(int i = expected_lines_count; i < max_check; i++)
   {
      string name = GenerateObjectName(id, i);
      if(ObjectExists(name))
      {
         ObjectDelete(0, name);
         removed++;
      }
      else
      {
         // If we hit a missing index early, assume no more exist
         break;
      }
   }
   
   if(removed > 0)
      Print("[Renderer] Cleaned up ", removed, " orphaned lines for ID: ", id);
}


};


#endif
