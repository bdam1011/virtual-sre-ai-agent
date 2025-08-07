import pandas as pd
import pygelf
import logging
import time
import re
from datetime import datetime
from pathlib import Path
import pytz

def main():
    """Graylog 日誌模擬器 - 將 CSV 檔案內容發送到 Graylog"""
    GRAYLOG_HOST = '104.199.248.173'
    GRAYLOG_PORT = 12201
    CSV_FILE = 'All-Messages-search-result.csv'
    
    print(f"=== Graylog 日誌模擬器 ===")
    print(f"目標: {GRAYLOG_HOST}:{GRAYLOG_PORT}")
    print(f"檔案: {CSV_FILE}")
    
    if not Path(CSV_FILE).exists():
        print(f"❌ 找不到檔案: {CSV_FILE}")
        return
    
    try:
        df = pd.read_csv(CSV_FILE)
        total_rows = len(df)
        print(f"✅ 讀取 {total_rows} 筆記錄")
        
        # 設定 GELF logger
        logger = logging.getLogger('graylog_simulator')
        logger.setLevel(logging.INFO)
        logger.handlers.clear()
        
        gelf_handler = pygelf.GelfTcpHandler(
            host=GRAYLOG_HOST, 
            port=GRAYLOG_PORT,
            debug=False,
            include_extra_fields=True
        )
        logger.addHandler(gelf_handler)
        
        print("📤 發送日誌中...")
        success_count = 0
        error_count = 0
        taipei_tz = pytz.timezone('Asia/Taipei')
        
        for index, row in df.iterrows():
            try:
                extra_fields = {}
                for column in df.columns:
                    if column not in ['message', 'timestamp']:
                        field_name = 'original_source' if column == 'source' else column
                        value = str(row[column]) if pd.notna(row[column]) and str(row[column]).strip() else ""
                        extra_fields[field_name] = value
                
                extra_fields.update({
                    'facility': 'SimulatorService',
                    'host': 'SimulatorService',
                    'csv_row': index + 1,
                    'import_timestamp': datetime.now().isoformat()
                })
                
                current_time = datetime.now(taipei_tz)
                extra_fields['timestamp'] = current_time.timestamp()
                
                original_message = str(row.get('message', f'CSV row {index + 1}'))
                
                # 替換時間戳格式
                iso_pattern = r'(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+\+\d{2}:\d{2})'
                log_pattern = r'(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3})'
                
                new_iso_time = current_time.strftime('%Y-%m-%dT%H:%M:%S.%f')[:-3] + '+08:00'
                new_log_time = current_time.strftime('%Y-%m-%d %H:%M:%S,%f')[:-3]
                
                message = original_message
                message = re.sub(iso_pattern, new_iso_time, message, count=1)
                message = re.sub(log_pattern, new_log_time, message, count=1)
                
                logger.info(message, extra=extra_fields)
                success_count += 1
                
                if (index + 1) % 1000 == 0 or (index + 1) == total_rows:
                    print(f"進度: {index + 1}/{total_rows} ({((index + 1)/total_rows*100):.1f}%)")
                
                time.sleep(0.01)
                
            except Exception as e:
                error_count += 1
                if error_count <= 5:  # 只顯示前 5 個錯誤
                    print(f"⚠️  第 {index + 1} 筆失敗: {e}")
                continue
        
        print(f"\n=== 完成 ===")
        print(f"✅ 成功: {success_count} 筆")
        print(f"❌ 失敗: {error_count} 筆")
        print(f"📊 成功率: {(success_count/total_rows*100):.1f}%")
        print(f"\n🌐 Graylog: http://{GRAYLOG_HOST}:9000 (admin/admin)")
        
    except Exception as e:
        print(f"❌ 執行錯誤: {e}")
        return

if __name__ == "__main__":
    main()
