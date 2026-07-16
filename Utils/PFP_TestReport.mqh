//+------------------------------------------------------------------+
//|                                           PFP_TestReport.mqh     |
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
//| Class: PFP_TestReport                                            |
//| Purpose: Generate and save detailed test reports                 |
//+------------------------------------------------------------------+
class PFP_TestReport
{
private:
   string             m_reportPath;
   string             m_logPath;
   int                m_totalTests;
   int                m_passedTests;
   int                m_failedTests;
   int                m_warnings;
   bool               m_allPassed;
   
   // Test results storage
   struct TestResult
   {
      string          testName;
      bool            passed;
      string          message;
      ulong           duration_ms;
   };
   
   TestResult         m_results[];
   int                m_resultCount;
   
public:
   PFP_TestReport();
   ~PFP_TestReport();
   
   // Initialization
   void               Initialize();
   
   // Recording Results
   void               RecordTest(string name, bool passed, string message = "", ulong duration_ms = 0);
   void               RecordWarning(string warning);
   
   // File Operations
   void               SaveReport();
   void               SaveLog(string message);
   
   // Summary
   string             GetSummary();
   bool               AllTestsPassed();
   
private:
   string             GenerateDetailedReport();
   void               WriteToFile(string filename, string content);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
PFP_TestReport::PFP_TestReport()
{
   m_totalTests = 0;
   m_passedTests = 0;
   m_failedTests = 0;
   m_warnings = 0;
   m_allPassed = true;
   m_resultCount = 0;
   m_reportPath = "\\MQL5\\Files\\PitchforkPro\\Tester_Report.txt";
   m_logPath = "\\MQL5\\Files\\PitchforkPro\\Tester_Log.txt";
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
PFP_TestReport::~PFP_TestReport()
{
}

//+------------------------------------------------------------------+
//| Initialize report                                                |
//+------------------------------------------------------------------+
void PFP_TestReport::Initialize()
{
   m_totalTests = 0;
   m_passedTests = 0;
   m_failedTests = 0;
   m_warnings = 0;
   m_allPassed = true;
   m_resultCount = 0;
   
   // Clear previous logs
   FileDelete(m_logPath);
   FileDelete(m_reportPath);
   
   string header = "=== PitchforkPro v1.0 Test Report ===\n";
   header += "Date: " + TimeToString(TimeCurrent()) + "\n";
   header += "Symbol: " + Symbol() + "\n";
   header += "Timeframe: " + EnumToString(Period()) + "\n\n";
   
   WriteToFile(m_logPath, header);
   PFP_Logger::Info("[TestReport] Test session initialized.");
}

//+------------------------------------------------------------------+
//| Record a test result                                             |
//+------------------------------------------------------------------+
void PFP_TestReport::RecordTest(string name, bool passed, string message = "", ulong duration_ms = 0)
{
   m_totalTests++;
   if(passed)
      m_passedTests++;
   else
   {
      m_failedTests++;
      m_allPassed = false;
   }
   
   // Store result
   int idx = ArrayResize(m_results, m_resultCount + 1);
   if(idx >= 0)
   {
      m_results[idx].testName = name;
      m_results[idx].passed = passed;
      m_results[idx].message = message;
      m_results[idx].duration_ms = duration_ms;
      m_resultCount++;
   }
   
   // Log immediately
   string status = passed ? "[PASS]" : "[FAIL]";
   string logEntry = StringFormat("%s %s (%d ms) - %s", status, name, duration_ms / 1000, message);
   SaveLog(logEntry);
   
   if(!passed)
      PFP_Logger::Error("[TestReport] Test failed: " + name + " - " + message);
}

//+------------------------------------------------------------------+
//| Record a warning                                                 |
//+------------------------------------------------------------------+
void PFP_TestReport::RecordWarning(string warning)
{
   m_warnings++;
   SaveLog("[WARN] " + warning);
   PFP_Logger::Warning("[TestReport] " + warning);
}

//+------------------------------------------------------------------+
//| Save detailed report to file                                     |
//+------------------------------------------------------------------+
void PFP_TestReport::SaveReport()
{
   string content = GenerateDetailedReport();
   WriteToFile(m_reportPath, content);
   PFP_Logger::Info("[TestReport] Report saved to: " + m_reportPath);
   
   // Also print summary to Experts tab
   Print(GetSummary());
}

//+------------------------------------------------------------------+
//| Append message to log file                                       |
//+------------------------------------------------------------------+
void PFP_TestReport::SaveLog(string message)
{
   string entry = TimeToString(TimeCurrent(), TIME_SECONDS) + " | " + message + "\n";
   
   int handle = FileOpen(m_logPath, FILE_WRITE | FILE_TXT | FILE_ANSI);
   if(handle != INVALID_HANDLE)
   {
      FileSeek(handle, 0, SEEK_END);
      FileWriteString(handle, entry, StringLen(entry));
      FileClose(handle);
   }
}

//+------------------------------------------------------------------+
//| Get text summary                                                 |
//+------------------------------------------------------------------+
string PFP_TestReport::GetSummary()
{
   string summary = "\n========================================\n";
   summary += "       PITCHFORKPRO TEST SUMMARY\n";
   summary += "========================================\n";
   summary += "TOTAL TESTS:    " + IntegerToString(m_totalTests) + "\n";
   summary += "PASSED:         " + IntegerToString(m_passedTests) + "\n";
   summary += "FAILED:         " + IntegerToString(m_failedTests) + "\n";
   summary += "WARNINGS:       " + IntegerToString(m_warnings) + "\n";
   summary += "STATUS:         " + (m_allPassed ? "ALL TESTS PASSED" : "SOME TESTS FAILED") + "\n";
   summary += "========================================\n";
   return summary;
}

//+------------------------------------------------------------------+
//| Check if all tests passed                                        |
//+------------------------------------------------------------------+
bool PFP_TestReport::AllTestsPassed()
{
   return m_allPassed;
}

//+------------------------------------------------------------------+
//| Generate detailed report content                                 |
//+------------------------------------------------------------------+
string PFP_TestReport::GenerateDetailedReport()
{
   string report = "=== PitchforkPro v1.0 Detailed Test Report ===\n\n";
   report += "Execution Date: " + TimeToString(TimeCurrent()) + "\n";
   report += "Symbol: " + Symbol() + "\n";
   report += "Timeframe: " + EnumToString(Period()) + "\n\n";
   
   report += "--- Summary ---\n";
   report += "Total Tests:  " + IntegerToString(m_totalTests) + "\n";
   report += "Passed:       " + IntegerToString(m_passedTests) + "\n";
   report += "Failed:       " + IntegerToString(m_failedTests) + "\n";
   report += "Warnings:     " + IntegerToString(m_warnings) + "\n";
   report += "Overall:      " + (m_allPassed ? "SUCCESS" : "FAILURE") + "\n\n";
   
   report += "--- Detailed Results ---\n";
   for(int i = 0; i < m_resultCount; i++)
   {
      string status = m_results[i].passed ? "PASS" : "FAIL";
      report += StringFormat("[%s] %s (%d ms)\n", status, m_results[i].testName, m_results[i].duration_ms / 1000);
      if(StringLen(m_results[i].message) > 0)
         report += "       Info: " + m_results[i].message + "\n";
   }
   
   report += "\n--- End of Report ---\n";
   return report;
}

//+------------------------------------------------------------------+
//| Helper: Write content to file                                    |
//+------------------------------------------------------------------+
void PFP_TestReport::WriteToFile(string filename, string content)
{
   int handle = FileOpen(filename, FILE_WRITE | FILE_TXT | FILE_ANSI);
   if(handle != INVALID_HANDLE)
   {
      FileWriteString(handle, content, StringLen(content));
      FileClose(handle);
   }
   else
   {
      PFP_Logger::Error("[TestReport] Failed to open file for writing: " + filename);
   }
}

#endif // PFP_DEBUG
