-- 插入角色组数据
INSERT INTO workspace_role_group (id, code, name, category, region, description, active, deleted, create_time, update_time)
VALUES
(1, 'rg-001', '技术支持组', '技术', 'Asia', '负责技术支持工作', true, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(2, 'rg-002', '客户服务组', '服务', 'Europe', '负责客户服务工作', true, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(3, 'rg-003', '运维组', '技术', 'America', '负责系统运维工作', true, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- 插入团队数据
INSERT INTO workspace_team (id, team_code, name, color, display_order, visible, description, deleted, create_time, update_time)
VALUES
(1, 'team-001', 'Alpha 团队', '#FF6B6B', 1, true, '核心技术支持团队', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(2, 'team-002', 'Beta 团队', '#4ECDC4', 2, true, '客户服务团队', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(3, 'team-003', 'Gamma 团队', '#45B7D1', 3, true, '系统运维团队', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- 插入团队和角色组的关系
INSERT INTO workspace_team_role_group_rel (id, team_id, role_group_id, create_time, update_time)
VALUES
(1, 1, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(2, 2, 2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(3, 3, 3, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- 插入员工数据
INSERT INTO workspace_staff (id, staff_code, name, email, phone, slack, region, timezone, role_name, role_group_id, status, avatar, notes, deleted, create_time, update_time)
VALUES
(1, 'staff-001', '张三', 'zhangsan@example.com', '13800138001', 'zhangsan', 'Asia', 'Asia/Shanghai', '高级技术支持', 1, 'Active', NULL, '技术专家', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(2, 'staff-002', '李四', 'lisi@example.com', '13800138002', 'lisi', 'Europe', 'Europe/London', '客户服务专员', 2, 'Active', NULL, '服务意识强', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(3, 'staff-003', '王五', 'wangwu@example.com', '13800138003', 'wangwu', 'America', 'America/New_York', '运维工程师', 3, 'Active', NULL, '系统专家', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(4, 'staff-004', '赵六', 'zhaoliu@example.com', '13800138004', 'zhaoliu', 'Asia', 'Asia/Shanghai', '技术支持专员', 1, 'Active', NULL, '学习能力强', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(5, 'staff-005', '钱七', 'qianqi@example.com', '13800138005', 'qianqi', 'Europe', 'Europe/Paris', '客户服务主管', 2, 'Active', NULL, '管理经验丰富', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- 插入班次定义
INSERT INTO workspace_shift_definition (id, role_group_id, code, meaning, start_time, end_time, timezone, primary_shift, visible, color_hex, remark, deleted, create_time, update_time)
VALUES
(1, 1, 'AM', '早班', '09:00:00', '17:00:00', 'Asia/Shanghai', true, true, '#FFD93D', '常规早班', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(2, 1, 'PM', '晚班', '17:00:00', '01:00:00', 'Asia/Shanghai', false, true, '#6B5B95', '常规晚班', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(3, 2, 'EU-AM', '欧洲早班', '09:00:00', '17:00:00', 'Europe/London', true, true, '#88B04B', '欧洲区域早班', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(4, 3, 'US-PM', '美国晚班', '17:00:00', '01:00:00', 'America/New_York', true, true, '#92A8D1', '美国区域晚班', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- 插入排班分配数据（最近7天的排班）
INSERT INTO workspace_roster_assignment (id, staff_id, role_group_id, team_id, shift_definition_id, assignment_date, shift_code, source_type, notes, deleted, create_time, update_time)
VALUES
(1, 1, 1, 1, 1, CURRENT_DATE - INTERVAL '6 days', 'AM', 'MANUAL', '常规早班', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(2, 2, 2, 2, 3, CURRENT_DATE - INTERVAL '6 days', 'EU-AM', 'MANUAL', '欧洲早班', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(3, 3, 3, 3, 4, CURRENT_DATE - INTERVAL '6 days', 'US-PM', 'MANUAL', '美国晚班', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(4, 4, 1, 1, 2, CURRENT_DATE - INTERVAL '5 days', 'PM', 'MANUAL', '常规晚班', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(5, 5, 2, 2, 3, CURRENT_DATE - INTERVAL '5 days', 'EU-AM', 'MANUAL', '欧洲早班', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(6, 1, 1, 1, 1, CURRENT_DATE - INTERVAL '4 days', 'AM', 'MANUAL', '常规早班', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(7, 3, 3, 3, 4, CURRENT_DATE - INTERVAL '4 days', 'US-PM', 'MANUAL', '美国晚班', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(8, 2, 2, 2, 3, CURRENT_DATE - INTERVAL '3 days', 'EU-AM', 'MANUAL', '欧洲早班', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(9, 4, 1, 1, 2, CURRENT_DATE - INTERVAL '3 days', 'PM', 'MANUAL', '常规晚班', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(10, 5, 2, 2, 3, CURRENT_DATE - INTERVAL '2 days', 'EU-AM', 'MANUAL', '欧洲早班', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(11, 1, 1, 1, 1, CURRENT_DATE - INTERVAL '2 days', 'AM', 'MANUAL', '常规早班', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(12, 3, 3, 3, 4, CURRENT_DATE - INTERVAL '1 day', 'US-PM', 'MANUAL', '美国晚班', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(13, 2, 2, 2, 3, CURRENT_DATE - INTERVAL '1 day', 'EU-AM', 'MANUAL', '欧洲早班', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(14, 4, 1, 1, 2, CURRENT_DATE, 'PM', 'MANUAL', '常规晚班', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(15, 5, 2, 2, 3, CURRENT_DATE, 'EU-AM', 'MANUAL', '欧洲早班', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
