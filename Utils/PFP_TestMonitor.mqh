//+------------------------------------------------------------------+
//|                                           PFP_TestMonitor.mqh    |
//|                                  Copyright 2024, PitchforkPro    |
//|                                             https://example.com  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, PitchforkPro"
#property link      "https://example.com"
#property version   "1.000"
#property strict

#ifdef PFP_DEBUG

#include <PFP_Logger.mqh>

//+------------------------------------------------------------------+
//| Class: PFP_TestMonitor                                           |
//| Purpose: Monitor memory, object count, and performance metrics   |
//+------------------------------------------------------------------+
class PFP_TestMonitor
{
private:
   ulong              m_startMemory;
   ulong              m_currentMemory;
   int                m_startObjectCount;
   int                m_currentObjectCount;
   ulong              m_totalRenderTime;
   ulong              m_totalSaveTime;
   int                m_renderCount;
   int                m_saveCount;
   ulong              m_maxMemory;
   int                m_maxObjectCount;
   datetime           m_lastCheckTime;
   
   // Timers for specific operations
   ulong              m_opStartTime;
   
public:
   PFP_TestMonitor();
   ~PFP_TestMonitor();
   
   // Initialization
   void               Initialize();
   
   // Snapshots
   void               TakeSnapshot();
   void               StartOperation();
   ulong              EndOperation();
   
   // Metrics Recording
   void               RecordRenderTime(ulong time_ns);
   void               RecordSaveTime(ulong time_ns);
   
   // Getters
   ulong              GetMemoryUsage();
   int                GetObjectCount();
   ulong              GetMaxMemory();
   int                GetMaxObjectCount();
   double             GetAvgRenderTime();
   double             GetAvgSaveTime();
   int                GetRenderCount();
   int                GetSaveCount();
   
   // Validation
   bool               CheckMemoryLeak();
   bool               CheckObjectLeak();
   string             GenerateSummary();
   
private:
   ulong              GetProcessMemory();
   int                CountPFPObjects();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
PFP_TestMonitor::PFP_TestMonitor()
{
   m_startMemory = 0;
   m_currentMemory = 0;
   m_startObjectCount = 0;
   m_currentObjectCount = 0;
   m_totalRenderTime = 0;
   m_totalSaveTime = 0;
   m_renderCount = 0;
   m_saveCount = 0;
   m_maxMemory = 0;
   m_maxObjectCount = 0;
   m_opStartTime = 0;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
PFP_TestMonitor::~PFP_TestMonitor()
{
}

//+------------------------------------------------------------------+
//| Initialize monitoring                                            |
//+------------------------------------------------------------------+
void PFP_TestMonitor::Initialize()
{
   m_startMemory = GetProcessMemory();
   m_startObjectCount = CountPFPObjects();
   m_currentMemory = m_startMemory;
   m_currentObjectCount = m_startObjectCount;
   m_maxMemory = m_startMemory;
   m_maxObjectCount = m_startObjectCount;
   m_lastCheckTime = TimeCurrent();
   
   PFP_Logger::Info("[TestMonitor] Monitoring initialized. Base Memory: " + IntegerToString(m_startMemory) + " KB, Base Objects: " + IntegerToString(m_startObjectCount));
}

//+------------------------------------------------------------------+
//| Take a snapshot of current state                                 |
//+------------------------------------------------------------------+
void PFP_TestMonitor::TakeSnapshot()
{
   m_currentMemory = GetProcessMemory();
   m_currentObjectCount = CountPFPObjects();
   
   if(m_currentMemory > m_maxMemory) m_maxMemory = m_currentMemory;
   if(m_currentObjectCount > m_maxObjectCount) m_maxObjectCount = m_currentObjectCount;
}

//+------------------------------------------------------------------+
//| Start timing an operation                                        |
//+------------------------------------------------------------------+
void PFP_TestMonitor::StartOperation()
{
   m_opStartTime = GetMicrosecondCount();
}

//+------------------------------------------------------------------+
//| End timing and return duration in nanoseconds                    |
//+------------------------------------------------------------------+
ulong PFP_TestMonitor::EndOperation()
{
   ulong end = GetMicrosecondCount();
   if(m_opStartTime == 0) return 0;
   return (end - m_opStartTime) * 1000; // Convert to ns
}

//+------------------------------------------------------------------+
//| Record render time                                               |
//+------------------------------------------------------------------+
void PFP_TestMonitor::RecordRenderTime(ulong time_ns)
{
   m_totalRenderTime += time_ns;
   m_renderCount++;
}

//+------------------------------------------------------------------+
//| Record save time                                                 |
//+------------------------------------------------------------------+
void PFP_TestMonitor::RecordSaveTime(ulong time_ns)
{
   m_totalSaveTime += time_ns;
   m_saveCount++;
}

//+------------------------------------------------------------------+
//| Get current memory usage                                         |
//+------------------------------------------------------------------+
ulong PFP_TestMonitor::GetMemoryUsage()
{
   return GetProcessMemory();
}

//+------------------------------------------------------------------+
//| Get current object count                                         |
//+------------------------------------------------------------------+
int PFP_TestMonitor::GetObjectCount()
{
   return CountPFPObjects();
}

//+------------------------------------------------------------------+
//| Get max memory recorded                                          |
//+------------------------------------------------------------------+
ulong PFP_TestMonitor::GetMaxMemory()
{
   return m_maxMemory;
}

//+------------------------------------------------------------------+
//| Get max object count recorded                                    |
//+------------------------------------------------------------------+
int PFP_TestMonitor::GetMaxObjectCount()
{
   return m_maxObjectCount;
}

//+------------------------------------------------------------------+
//| Get average render time (ms)                                     |
//+------------------------------------------------------------------+
double PFP_TestMonitor::GetAvgRenderTime()
{
   if(m_renderCount == 0) return 0.0;
   return (double)m_totalRenderTime / m_renderCount / 1000000.0; // ns to ms
}

//+------------------------------------------------------------------+
//| Get average save time (ms)                                       |
//+------------------------------------------------------------------+
double PFP_TestMonitor::GetAvgSaveTime()
{
   if(m_saveCount == 0) return 0.0;
   return (double)m_totalSaveTime / m_saveCount / 1000000.0; // ns to ms
}

//+------------------------------------------------------------------+
//| Get render count                                                 |
//+------------------------------------------------------------------+
int PFP_TestMonitor::GetRenderCount()
{
   return m_renderCount;
}

//+------------------------------------------------------------------+
//| Get save count                                                   |
//+------------------------------------------------------------------+
int PFP_TestMonitor::GetSaveCount()
{
   return m_saveCount;
}

//+------------------------------------------------------------------+
//| Check for memory leak                                            |
//+------------------------------------------------------------------+
bool PFP_TestMonitor::CheckMemoryLeak()
{
   ulong current = GetProcessMemory();
   // Allow 5% variance due to MT5 internal fluctuations
   ulong threshold = m_startMemory + (m_startMemory / 20); 
   if(current > threshold)
   {
      PFP_Logger::Warning("[TestMonitor] Potential Memory Leak detected! Start: " + IntegerToString(m_startMemory) + ", Current: " + IntegerToString(current));
      return false;
   }
   return true;
}

//+------------------------------------------------------------------+
//| Check for object leak                                            |
//+------------------------------------------------------------------+
bool PFP_TestMonitor::CheckObjectLeak()
{
   int current = CountPFPObjects();
   if(current != m_startObjectCount)
   {
      PFP_Logger::Warning("[TestMonitor] Object Leak detected! Start: " + IntegerToString(m_startObjectCount) + ", Current: " + IntegerToString(current));
      return false;
   }
   return true;
}

//+------------------------------------------------------------------+
//| Generate summary report                                          |
//+------------------------------------------------------------------+
string PFP_TestMonitor::GenerateSummary()
{
   string report = "--- Test Monitor Summary ---\n";
   report += "Memory Usage: " + IntegerToString(GetMemoryUsage()) + " KB\n";
   report += "Max Memory: " + IntegerToString(m_maxMemory) + " KB\n";
   report += "Object Count: " + IntegerToString(GetObjectCount()) + "\n";
   report += "Max Objects: " + IntegerToString(m_maxObjectCount) + "\n";
   report += "Avg Render Time: " + DoubleToString(GetAvgRenderTime(), 3) + " ms\n";
   report += "Avg Save Time: " + DoubleToString(GetAvgSaveTime(), 3) + " ms\n";
   report += "Total Renders: " + IntegerToString(m_renderCount) + "\n";
   report += "Total Saves: " + IntegerToString(m_saveCount) + "\n";
   report += "Memory Leak Check: " + (CheckMemoryLeak() ? "PASSED" : "FAILED") + "\n";
   report += "Object Leak Check: " + (CheckObjectLeak() ? "PASSED" : "FAILED") + "\n";
   return report;
}

//+------------------------------------------------------------------+
//| Helper: Get process memory (simulated via TerminalInfo)          |
//+------------------------------------------------------------------+
ulong PFP_TestMonitor::GetProcessMemory()
{
   // Note: Direct process memory access is limited in MQL5. 
   // We use TerminalInfoInteger as a proxy or estimate based on object count if needed.
   // For accurate testing, external tools are recommended, but this gives a trend.
   return TerminalInfoInteger(TERMINAL_MEMORY_USED) / 1024; // KB
}

//+------------------------------------------------------------------+
//| Helper: Count PFP Objects                                        |
//+------------------------------------------------------------------+
int PFP_TestMonitor::CountPFPObjects()
{
   int count = 0;
   int total = ObjectsTotal(0, 0, -1);
   for(int i = 0; i < total; i++)
   {
      string name = ObjectName(0, i, 0, -1);
      if(StringFind(name, "PFP_") == 0) count++;
   }
   return count;
}

#endif // PFP_DEBUG
