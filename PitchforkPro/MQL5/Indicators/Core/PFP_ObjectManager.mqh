//+------------------------------------------------------------------+
//|                                              PFP_ObjectManager.mqh |
//|                        Copyright 2024, PitchforkPro Project      |
//|                                             https://github.com/  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, PitchforkPro Project"
#property link      "https://github.com/"
#property version   "1.0.0"
#property description "مدیریت مرکزی اشیاء، Registry مبتنی بر ID و Garbage Collection"

#include "PFP_Logger.mqh"
#include "PFP_GeometryEngine.mqh"

//+------------------------------------------------------------------+
//| ساختار اطلاعات شیء                                               |
//+------------------------------------------------------------------+
struct PFP_ObjectInfo
{
   long              id;             // شناسه یکتا
   string            name_prefix;    // پیشوند نام (مثلا PFP_)
   datetime          time1, time2, time3; // نقاط زمانی
   double            price1, price2, price3; // نقاط قیمتی
   ENUM_PFP_TYPE     type;           // نوع پیچ‌فورک
   ENUM_PFP_DIR      direction;      // جهت
   bool              is_active;      // آیا فعال است
   datetime          last_update;    // زمان آخرین بروزرسانی
   bool              is_valid;       // اعتبار داده‌ها
   
   void Reset()
   {
      id = -1;
      name_prefix = "";
      time1 = time2 = time3 = 0;
      price1 = price2 = price3 = 0;
      type = PFP_STANDARD;
      direction = PFP_BULLISH;
      is_active = false;
      last_update = 0;
      is_valid = false;
   }
};

//+------------------------------------------------------------------+
//| کلاس مدیریت اشیاء                                                 |
//+------------------------------------------------------------------+
class PFP_ObjectManager
{
private:
   PFP_Logger        m_logger;
   map<long, PFP_ObjectInfo> m_registry; // Registry مبتنی بر ID
   map<string, long> m_name_to_id;       // نگاشت نام به ID برای جستجوی سریع
   bool              m_initialized;
   int               m_cleanup_counter;  // شمارنده برای Garbage Collection
   
   // تنظیمات
   int               m_gc_threshold;     // آستانه اجرای GC
   bool              m_auto_sync;        // همگام‌سازی خودکار

   // متدهای کمکی خصوصی
   string            GenerateObjectName(long id, int line_index);
   bool              ValidateObjectInfo(const PFP_ObjectInfo &info);
   void              InternalCleanup();
   bool              CheckChartSync();

public:
                     PFP_ObjectManager();
                    ~PFP_ObjectManager();
   
   // مدیریت چرخه حیات
   bool              Initialize();
   void              Deinitialize();
   bool              IsInitialized() const { return m_initialized; }
   
   // ثبت و حذف
   bool              Register(long id, const PFP_ObjectInfo &info);
   bool              Unregister(long id);
   bool              UnregisterAll();
   
   // دسترسی به داده‌ها
   bool              GetInfo(long id, PFP_ObjectInfo &out_info) const;
   bool              HasObject(long id) const;
   int               GetCount() const { return m_registry.Size(); }
   long              GetIdByIndex(int index) const;
   
   // جستجو
   long              FindIdByName(const string &name) const;
   bool              FindIdsByTimeRange(datetime start, datetime end, long &ids[]);
   
   // به‌روزرسانی
   bool              UpdateInfo(long id, const PFP_ObjectInfo &new_info);
   bool              Touch(long id); // بروزرسانی زمان آخرین دسترسی
   
   // همگام‌سازی و پاکسازی
   bool              SyncWithChart();
   void              ForceGarbageCollection();
   void              SetAutoSync(bool enable) { m_auto_sync = enable; }
   
   // مدیریت نام‌ها
   string            GetObjectName(long id, int line_index) const;
   bool              IsPfpObject(const string &name) const;
   
   // دیباگ و لاگ
   void              PrintRegistry() const;
   string            GetStats() const;
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
PFP_ObjectManager::PFP_ObjectManager() : m_initialized(false), m_cleanup_counter(0), 
                                         m_gc_threshold(50), m_auto_sync(true)
{
   m_logger.SetPrefix("[ObjMgr]");
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
PFP_ObjectManager::~PFP_ObjectManager()
{
   Deinitialize();
}

//+------------------------------------------------------------------+
//| Initialize                                                       |
//+------------------------------------------------------------------+
bool PFP_ObjectManager::Initialize()
{
   if(m_initialized)
   {
      m_logger.Warning("Already initialized.");
      return true;
   }
   
   m_registry.Clear();
   m_name_to_id.Clear();
   m_cleanup_counter = 0;
   m_initialized = true;
   
   m_logger.Info("ObjectManager initialized successfully.");
   return true;
}

//+------------------------------------------------------------------+
//| Deinitialize                                                     |
//+------------------------------------------------------------------+
void PFP_ObjectManager::Deinitialize()
{
   if(!m_initialized) return;
   
   UnregisterAll();
   m_registry.Clear();
   m_name_to_id.Clear();
   m_initialized = false;
   
   m_logger.Info("ObjectManager deinitialized.");
}

//+------------------------------------------------------------------+
//| Register                                                         |
//+------------------------------------------------------------------+
bool PFP_ObjectManager::Register(long id, const PFP_ObjectInfo &info)
{
   if(!m_initialized)
   {
      m_logger.Error("Not initialized. Cannot register.");
      return false;
   }
   
   if(!ValidateObjectInfo(info))
   {
      m_logger.Error("Invalid object info for ID: " + IntegerToString(id));
      return false;
   }
   
   if(m_registry.ContainsKey(id))
   {
      m_logger.Warning("ID already exists, updating: " + IntegerToString(id));
      return UpdateInfo(id, info);
   }
   
   PFP_ObjectInfo new_info = info;
   new_info.id = id;
   new_info.last_update = TimeCurrent();
   new_info.is_active = true;
   
   if(!m_registry.Put(id, new_info))
   {
      m_logger.Error("Failed to put into registry: " + IntegerToString(id));
      return false;
   }
   
   // ثبت نگاشت نام
   string base_name = GenerateObjectName(id, 0);
   if(!m_name_to_id.ContainsKey(base_name))
      m_name_to_id.Put(base_name, id);
   
   m_logger.Debug("Registered ID: " + IntegerToString(id));
   
   // بررسی GC
   m_cleanup_counter++;
   if(m_cleanup_counter >= m_gc_threshold)
      InternalCleanup();
      
   return true;
}

//+------------------------------------------------------------------+
//| Unregister                                                       |
//+------------------------------------------------------------------+
bool PFP_ObjectManager::Unregister(long id)
{
   if(!m_registry.ContainsKey(id))
      return false;
      
   PFP_ObjectInfo info;
   if(m_registry.Get(id, info))
   {
      string base_name = GenerateObjectName(id, 0);
      if(m_name_to_id.ContainsKey(base_name))
         m_name_to_id.Remove(base_name);
   }
   
   bool result = m_registry.Remove(id);
   if(result)
      m_logger.Debug("Unregistered ID: " + IntegerToString(id));
      
   return result;
}

//+------------------------------------------------------------------+
//| UnregisterAll                                                    |
//+------------------------------------------------------------------+
bool PFP_ObjectManager::UnregisterAll()
{
   m_registry.Clear();
   m_name_to_id.Clear();
   m_logger.Info("All objects unregistered.");
   return true;
}

//+------------------------------------------------------------------+
//| GetInfo                                                          |
//+------------------------------------------------------------------+
bool PFP_ObjectManager::GetInfo(long id, PFP_ObjectInfo &out_info) const
{
   return m_registry.Get(id, out_info);
}

//+------------------------------------------------------------------+
//| HasObject                                                        |
//+------------------------------------------------------------------+
bool PFP_ObjectManager::HasObject(long id) const
{
   return m_registry.ContainsKey(id);
}

//+------------------------------------------------------------------+
//| GetIdByIndex                                                     |
//+------------------------------------------------------------------+
long PFP_ObjectManager::GetIdByIndex(int index) const
{
   if(index < 0 || index >= m_registry.Size())
      return -1;
      
   long keys[];
   m_registry.Keys(keys);
   return keys[index];
}

//+------------------------------------------------------------------+
//| FindIdByName                                                     |
//+------------------------------------------------------------------+
long PFP_ObjectManager::FindIdByName(const string &name) const
{
   long id;
   if(m_name_to_id.Get(name, id))
      return id;
   return -1;
}

//+------------------------------------------------------------------+
//| FindIdsByTimeRange                                               |
//+------------------------------------------------------------------+
bool PFP_ObjectManager::FindIdsByTimeRange(datetime start, datetime end, long &ids[])
{
   ArrayResize(ids, 0);
   long keys[];
   m_registry.Keys(keys);
   
   for(int i = 0; i < ArraySize(keys); i++)
   {
      PFP_ObjectInfo info;
      if(m_registry.Get(keys[i], info))
      {
         if((info.time1 >= start && info.time1 <= end) ||
            (info.time2 >= start && info.time2 <= end) ||
            (info.time3 >= start && info.time3 <= end))
         {
            int size = ArraySize(ids);
            ArrayResize(ids, size + 1);
            ids[size] = keys[i];
         }
      }
   }
   return ArraySize(ids) > 0;
}

//+------------------------------------------------------------------+
//| UpdateInfo                                                       |
//+------------------------------------------------------------------+
bool PFP_ObjectManager::UpdateInfo(long id, const PFP_ObjectInfo &new_info)
{
   if(!m_registry.ContainsKey(id))
      return false;
      
   PFP_ObjectInfo current;
   if(!m_registry.Get(id, current))
      return false;
      
   // فقط فیلدهای خاصی را آپدیت می‌کنیم
   current.time1 = new_info.time1;
   current.time2 = new_info.time2;
   current.time3 = new_info.time3;
   current.price1 = new_info.price1;
   current.price2 = new_info.price2;
   current.price3 = new_info.price3;
   current.type = new_info.type;
   current.direction = new_info.direction;
   current.last_update = TimeCurrent();
   current.is_valid = ValidateObjectInfo(current);
   
   if(!current.is_valid)
   {
      m_logger.Warning("Update made object invalid: " + IntegerToString(id));
   }
   
   bool res = m_registry.Put(id, current);
   if(res)
      m_logger.Debug("Updated ID: " + IntegerToString(id));
   return res;
}

//+------------------------------------------------------------------+
//| Touch                                                            |
//+------------------------------------------------------------------+
bool PFP_ObjectManager::Touch(long id)
{
   if(!m_registry.ContainsKey(id))
      return false;
      
   PFP_ObjectInfo info;
   if(m_registry.Get(id, info))
   {
      info.last_update = TimeCurrent();
      return m_registry.Put(id, info);
   }
   return false;
}

//+------------------------------------------------------------------+
//| SyncWithChart                                                    |
//+------------------------------------------------------------------+
bool PFP_ObjectManager::SyncWithChart()
{
   if(!m_auto_sync) return true;
   
   // بررسی وجود فیزیکی اشیاء در چارت
   long keys[];
   m_registry.Keys(keys);
   
   int removed_count = 0;
   for(int i = 0; i < ArraySize(keys); i++)
   {
      long id = keys[i];
      PFP_ObjectInfo info;
      if(m_registry.Get(id, info))
      {
         string obj_name = GenerateObjectName(id, 0);
         if(ObjectFind(0, obj_name) < 0)
         {
            // شیء از چارت حذف شده است
            m_logger.Info("Object deleted manually from chart: " + obj_name + " (ID:" + IntegerToString(id) + ")");
            Unregister(id);
            removed_count++;
         }
      }
   }
   
   if(removed_count > 0)
   {
      m_logger.Warning("Sync removed " + IntegerToString(removed_count) + " orphaned entries.");
      return false; // تغییر اتفاق افتاده
   }
   return true;
}

//+------------------------------------------------------------------+
//| ForceGarbageCollection                                           |
//+------------------------------------------------------------------+
void PFP_ObjectManager::ForceGarbageCollection()
{
   m_logger.Info("Forcing Garbage Collection...");
   InternalCleanup();
}

//+------------------------------------------------------------------+
//| InternalCleanup                                                  |
//+------------------------------------------------------------------+
void PFP_ObjectManager::InternalCleanup()
{
   m_cleanup_counter = 0;
   SyncWithChart();
   // اینجا می‌توان منطق پیچیده‌تری برای پاکسازی اضافه کرد
   // مثلاً حذف اشیایی که مدت زیادی است آپدیت نشده‌اند
}

//+------------------------------------------------------------------+
//| GenerateObjectName                                               |
//+------------------------------------------------------------------+
string PFP_ObjectManager::GenerateObjectName(long id, int line_index)
{
   return StringFormat("PFP_%d_L%d", id, line_index);
}

//+------------------------------------------------------------------+
//| ValidateObjectInfo                                               |
//+------------------------------------------------------------------+
bool PFP_ObjectManager::ValidateObjectInfo(const PFP_ObjectInfo &info)
{
   if(info.time1 == 0 || info.time2 == 0 || info.time3 == 0)
      return false;
   if(info.price1 == 0 || info.price2 == 0 || info.price3 == 0)
      return false;
   if(info.time1 >= info.time3) // ترتیب زمانی باید رعایت شود
      return false;
      
   return true;
}

//+------------------------------------------------------------------+
//| GetObjectName                                                    |
//+------------------------------------------------------------------+
string PFP_ObjectManager::GetObjectName(long id, int line_index) const
{
   return StringFormat("PFP_%d_L%d", id, line_index);
}

//+------------------------------------------------------------------+
//| IsPfpObject                                                      |
//+------------------------------------------------------------------+
bool PFP_ObjectManager::IsPfpObject(const string &name) const
{
   return StringFind(name, "PFP_") == 0;
}

//+------------------------------------------------------------------+
//| PrintRegistry                                                    |
//+------------------------------------------------------------------+
void PFP_ObjectManager::PrintRegistry() const
{
   m_logger.Info("=== Registry Dump ===");
   long keys[];
   m_registry.Keys(keys);
   for(int i = 0; i < ArraySize(keys); i++)
   {
      PFP_ObjectInfo info;
      if(m_registry.Get(keys[i], info))
      {
         m_logger.Info("ID: " + IntegerToString(info.id) + 
                       " Type: " + EnumToString(info.type) + 
                       " Valid: " + (info.is_valid ? "Yes" : "No"));
      }
   }
   m_logger.Info("=== End Dump ===");
}

//+------------------------------------------------------------------+
//| GetStats                                                         |
//+------------------------------------------------------------------+
string PFP_ObjectManager::GetStats() const
{
   return StringFormat("Objects: %d, GC Counter: %d, AutoSync: %s", 
                       m_registry.Size(), 
                       m_cleanup_counter, 
                       m_auto_sync ? "On" : "Off");
}
//+------------------------------------------------------------------+
