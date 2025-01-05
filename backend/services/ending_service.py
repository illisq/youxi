class EndingService:
    def __init__(self, db_session):
        self.db = db_session
        
    def check_ending_conditions(self, session_id):
        """检查是否触发任何结局"""
        player_status = self.db.query(PlayerStatus).filter_by(session_id=session_id).first()
        events = self.db.query(GameEvent).filter_by(session_id=session_id).all()
        
        endings = []
        
        # 结局一：平庸裁员
        if self._check_ending_one(player_status, events):
            endings.append({
                "ending_id": 1,
                "name": "平庸裁员",
                "description": "在某个平凡的早晨，你收到了HR的邮件..."
            })
            
        # 结局二：不光彩离职
        if self._check_ending_two(player_status, events):
            endings.append({
                "ending_id": 2,
                "name": "不光彩离职",
                "description": "你成功获取了裁员名单，但代价是违反了公司的规定和职业道德..."
            })
            
        # 结局三：邪教信徒
        if self._check_ending_three(player_status, events):
            endings.append({
                "ending_id": 3,
                "name": "邪教信徒",
                "description": "在一次次与刘总监的接触中，你逐渐被他的言论所吸引..."
            })
            
        # 结局四：正义揭发
        if self._check_ending_four(player_status, events):
            endings.append({
                "ending_id": 4,
                "name": "正义揭发",
                "description": "在收集足够证据后，你选择向警方举报了刘总监的邪教组织..."
            })
            
        # 结局五：默许与妥协
        if self._check_ending_five(player_status, events):
            endings.append({
                "ending_id": 5,
                "name": "默许与妥协",
                "description": "当你发现陈总的诈骗计划时，他给了你一笔可观的封口费..."
            })
            
        # 结局六：背叛与牺牲
        if self._check_ending_six(player_status, events):
            endings.append({
                "ending_id": 6,
                "name": "背叛与牺牲",
                "description": "你选择揭露陈总的诈骗计划，成功阻止了更多投资人上当..."
            })
            
        return endings

    def _check_ending_one(self, status, events):
        """平庸裁员结局"""
        days_passed = len(set(e.created_at.date() for e in events))
        return (
            status.sanity_value >= 70 and
            status.alienation_value <= 20 and
            40 <= status.chen_influence <= 60 and
            40 <= status.liu_influence <= 60 and
            len(status.discovered_secrets) == 0 and
            days_passed >= 10  # 游戏进行超过10天
        )
    
    def _check_ending_two(self, status, events):
        """不光彩离职结局"""
        has_illegal_access = any(
            e.event_type == "investigation" and 
            e.event_data.get("action") == "illegal_access" and
            e.event_data.get("detected") == True
            for e in events
        )
        return (
            has_illegal_access and
            "layoff_list" in status.discovered_secrets and
            status.sanity_value >= 40 and
            status.sanity_value <= 70
        )
    
    def _check_ending_three(self, status, events):
        """邪教信徒结局"""
        ritual_count = sum(1 for e in events if e.event_type == "ritual_participation")
        return (
            status.sanity_value <= 30 and
            status.alienation_value >= 70 and
            status.liu_influence >= 90 and
            ritual_count >= 3 and
            "liu_cult" in status.discovered_secrets
        )
    
    def _check_ending_four(self, status, events):
        """正义揭发结局"""
        has_reported = any(e.event_type == "police_report" for e in events)
        return (
            status.sanity_value >= 50 and
            "liu_cult" in status.discovered_secrets and
            "ritual_evidence" in status.discovered_secrets and
            has_reported
        )
    
    def _check_ending_five(self, status, events):
        """默许与妥协结局"""
        has_accepted_bribe = any(e.event_type == "bribe_acceptance" for e in events)
        return (
            "chen_fraud" in status.discovered_secrets and
            has_accepted_bribe and
            status.chen_influence >= 80
        )
    
    def _check_ending_six(self, status, events):
        """背叛与牺牲结局"""
        has_exposed_fraud = any(e.event_type == "fraud_exposure" for e in events)
        return (
            "chen_fraud" in status.discovered_secrets and
            has_exposed_fraud and
            status.chen_influence <= 20
        ) 