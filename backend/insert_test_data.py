from database import get_db_connection

def insert_test_modules():
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        # # 先清空现有数据
        # cursor.execute("DELETE FROM modules")
        
        # 插入测试数据
        cursor.execute("""
            INSERT INTO modules (module_id, title, description, player_min, player_max, duration_hours, difficulty, create_time) VALUES 
            (2, '公司危机', '一个关于公司内部权力斗争的剧本', 4, 6, 4, 'medium', CURRENT_TIMESTAMP),
            (3, '魔法学院', '魔法学院中发生的神秘事件', 3, 5, 3, 'easy', CURRENT_TIMESTAMP),
            (4, '荒野求生', '在荒野中生存并解开谜题', 2, 4, 5, 'hard', CURRENT_TIMESTAMP);
        """)
        conn.commit()
        print("测试数据插入成功！")
    except Exception as e:
        conn.rollback()
        print(f"Error inserting test data: {e}")
    finally:
        cursor.close()
        conn.close()

if __name__ == "__main__":
    insert_test_modules() 