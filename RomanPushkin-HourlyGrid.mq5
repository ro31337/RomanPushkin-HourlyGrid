//+------------------------------------------------------------------+
//|                                                  Hourly-Grid.mq5 |
//|                                    Copyright 2013, Roman Pushkin |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#include <ChartObjects\ChartObjectsTxtControls.mqh>
#property copyright "Copyright 2013, Roman Pushkin"
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
//+----------------------------------------------+ 
//| Входные параметры индикатора                 |
//+----------------------------------------------+ 
string object_token_prefix = "hourly_line_"; // Название линии
input color Line_Color=SteelBlue;                // Цвет линии
input int max_hourly_lines = 24; // максимальное количество часовых линий
//+------------------------------------------------------------------+
//|  Создание вертикальной линии                                     |
//+------------------------------------------------------------------+
void CreateVline(long     chart_id,      // идентификатор графика
                 string   name,          // имя объекта
                 int      nwin,          // индекс окна
                 datetime time1,         // время вертикального уровня
                 color    Color,         // цвет линии
                 int      style,         // стиль линии
                 int      width,         // толщина линии
                 bool     background,    // фоновое отображение линии
                 string   text)          // текст
  {
//----
   ObjectCreate(chart_id,name,OBJ_VLINE,nwin,time1,999999999);
   ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
   ObjectSetInteger(chart_id,name,OBJPROP_STYLE,style);
   ObjectSetInteger(chart_id,name,OBJPROP_WIDTH,width);
   ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,background);
   ObjectSetInteger(chart_id,name,OBJPROP_RAY,true);
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   EventSetTimer(1);   
//---
   return(INIT_SUCCEEDED);
  }
  
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+     
void OnDeinit(const int reason)
{
   delete_all_objects();
   EventKillTimer();
   ChartRedraw(0);
}  

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---
   if(id == CHARTEVENT_CHART_CHANGE ||
      id == CHARTEVENT_OBJECT_DRAG)
      {
         OnTimer();
      }
   
  }

long previous_first_visible_bar = -1;
long previous_width_in_bars = -1;

CChartObjectLabel labels[100];

void OnTimer()
  {
   long chart_width = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0);
   long chart_height = ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0);

//---

   long first_visible_bar = ChartGetInteger(0, CHART_FIRST_VISIBLE_BAR, 0);
   long width_in_bars = ChartGetInteger(0, CHART_WIDTH_IN_BARS, 0);
   
   // check if scrolled or scale changed or new bar has appeared
   
   if(previous_first_visible_bar == first_visible_bar &&
      previous_width_in_bars == width_in_bars)
      return;
   
   previous_first_visible_bar = first_visible_bar;
   previous_width_in_bars = width_in_bars;

   // we must update labels now

   int objects_count = ObjectsTotal(0, 0, -1) - 1;

   string current_object_name, temp;
   
   // delete all labels
   
   delete_all_labels();
   
   // iterate thru all the objects
   int cnt = 0;
   for(int i = 0; i < objects_count; i++)
   {
      // fetch object name
      current_object_name = ObjectName(0, i, 0, -1);
      temp = StringSubstr(current_object_name, 0, StringLen(object_token_prefix));

      // if starts with token_prefix, use this object
      if(temp == object_token_prefix)
      {
         // get time
         
         datetime object_time = (datetime) ObjectGetInteger(0, current_object_name, OBJPROP_TIME, 0);
         
         // get X coordinate
         
         int x, y;
         
         if(ChartTimePriceToXY(0, 0, object_time, 0, x, y) &&
            x > 0 &&
            x < chart_width )
         {
            
            labels[cnt].Create(0, "label_" + object_token_prefix + IntegerToString(cnt), 0, x - 12, chart_height - 20);
            MqlDateTime object_time_struct;
            TimeToStruct(object_time, object_time_struct);
            
            labels[cnt].Description(StringFormat("%02d:%02d", object_time_struct.hour, object_time_struct.min ));
            labels[cnt].Color((color)(0xFFFFFF));
            labels[cnt].Font("Tahoma");
            labels[cnt].FontSize(7);
            
            cnt++;
         }
         
      }
   }
   
   ChartRedraw(0);

   
  }
  
void delete_all_labels()
{
   // we must update labels now

   int objects_count = ObjectsTotal(0, 0, -1) - 1;

   string current_object_name, temp;
   
   // iterate thru all the objects
   
   string search_pattern = "label_" + object_token_prefix;
   
   for(int i = objects_count; i >= 0 && !IsStopped(); i--)
   {
      // fetch object name
      current_object_name = ObjectName(0, i, 0, -1);
      temp = StringSubstr(current_object_name, 0, StringLen(search_pattern));

      // if starts with token_prefix, use this object
      if(temp == search_pattern)
      {
         ObjectDelete(0, current_object_name);
      }
   }


}


void delete_all_objects()
{
   int objects_count = ObjectsTotal(0, 0, -1) - 1;

   string current_object_name, temp;
   
   // iterate thru all the objects
   
   for(int i = objects_count; i >= 0 && !IsStopped(); i--)
   {
      // fetch object name
      current_object_name = ObjectName(0, i, 0, -1);
      temp = StringSubstr(current_object_name, 0, StringLen(object_token_prefix));

      // if starts with token_prefix, delete object
      if(temp == object_token_prefix) ObjectDelete(0, current_object_name);
   }

   ChartRedraw(0);   
}

bool is_object_exists(string object_name)
{
   // get objects count
   int objects_count = ObjectsTotal(0, 0, -1) - 1;
   
   string current_object_name;
   
   // iterate thru each object
   for(int i = 0; i < objects_count; i++)
   {
      current_object_name = ObjectName(0, i, 0, -1);
      
      if(current_object_name == object_name)
         return true;      
   }
   return false;
}
int previous_rates_total = 0;

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {

   // minimum period is M30
   
   if(Period() > PERIOD_M30) return 0;
   
   // we must have more than 2 bars
   
   if(rates_total < 2) return 0;

   // check if update required

   long first_visible_bar = ChartGetInteger(0, CHART_FIRST_VISIBLE_BAR, 0);
   long width_in_bars = ChartGetInteger(0, CHART_WIDTH_IN_BARS, 0);
   
   // check if update required
   if(previous_rates_total == rates_total)
      return 0;
   
   previous_rates_total = rates_total;

   // iterate thru each bar until max value reached

   int max = max_hourly_lines;

   for(int i = rates_total - 2; i > 0; i--)
   {
      datetime current_bar_time = time[i];
      datetime next_bar_time = time[i+1]; 
   
      if(is_first_hourly_bar(current_bar_time, next_bar_time) && !is_first_daily_bar(current_bar_time, next_bar_time))
      {
         draw_vertical_line(next_bar_time);
         draw_time(next_bar_time);
         max--;
         
         if(max == 0)
            break;
      }
   }
   
   ChartRedraw(0);   

   return(rates_total);
  }
//+------------------------------------------------------------------+

string get_object_token(datetime time)
{
   return object_token_prefix + TimeToString(time);
}

bool is_first_hourly_bar(datetime current_bar_time, datetime next_bar_time)
{
   MqlDateTime tmp1, tmp2;
   TimeToStruct(current_bar_time, tmp1);
   TimeToStruct(next_bar_time, tmp2);

   if(tmp1.hour != tmp2.hour)
      return true;
   
   return false;
}

bool is_first_daily_bar(datetime current_bar_time, datetime next_bar_time)
{
   MqlDateTime tmp1, tmp2;
   TimeToStruct(current_bar_time, tmp1);
   TimeToStruct(next_bar_time, tmp2);
   
   if(tmp1.day_of_year != tmp2.day_of_year)
      return true;
   
   return false;
}

void draw_vertical_line(datetime line_time)
{
   string object_token = get_object_token(line_time);
   
   if(!is_object_exists(object_token))
   {
      CreateVline(0, object_token, 0, line_time, Line_Color, 2, 1, true, "");   
   }
}

void draw_time(datetime time)
{
   
}