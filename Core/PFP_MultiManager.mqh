#ifndef PFP_MULTIMANAGER_MQH
#define PFP_MULTIMANAGER_MQH

#include "PFP_Pitchfork.mqh"

#define PFP_MAX_PITCHFORKS 100

class CPFP_MultiManager
{
private:

   CPFP_Pitchfork m_pitchforks[PFP_MAX_PITCHFORKS];

   int m_count;

public:

   //--------------------------------------------------

   CPFP_MultiManager()
   {
      Clear();
   }

   //--------------------------------------------------

   void Clear()
   {
      m_count=0;

      for(int i=0;i<PFP_MAX_PITCHFORKS;i++)
         m_pitchforks[i].Reset();
   }

   //--------------------------------------------------

   int Count() const
   {
      return m_count;
   }

   //--------------------------------------------------

   bool Add(CPFP_Pitchfork &pf)
   {
      if(!pf.Validate())
         return false;

      if(m_count>=PFP_MAX_PITCHFORKS)
         return false;

      m_pitchforks[m_count]=pf;

      m_count++;

      return true;
   }

   //--------------------------------------------------

   bool Remove(string id)
   {
      for(int i=0;i<m_count;i++)
      {
         if(m_pitchforks[i].ID()==id)
         {
            for(int j=i;j<m_count-1;j++)
               m_pitchforks[j]=m_pitchforks[j+1];

            m_pitchforks[m_count-1].Reset();

            m_count--;

            return true;
         }
      }

      return false;
   }

   //--------------------------------------------------

   bool Find(string id,CPFP_Pitchfork &pf)
   {
      for(int i=0;i<m_count;i++)
      {
         if(m_pitchforks[i].ID()==id)
         {
            pf=m_pitchforks[i];
            return true;
         }
      }

      return false;
   }

   //--------------------------------------------------

   bool Get(int index,CPFP_Pitchfork &pf)
   {
      if(index<0 || index>=m_count)
         return false;

      pf=m_pitchforks[index];

      return true;
   }

};

#endif