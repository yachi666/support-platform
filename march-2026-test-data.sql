-- 清理现有数据
DELETE FROM workspace_roster_assignment;
DELETE FROM workspace_shift_definition;
DELETE FROM workspace_staff;
DELETE FROM workspace_team_role_group_rel;
DELETE FROM workspace_team;
DELETE FROM workspace_role_group;

-- 重置序列
SELECT setval('workspace_role_group_id_seq', 1, false);
SELECT setval('workspace_team_id_seq', 1, false);
SELECT setval('workspace_staff_id_seq', 1, false);
SELECT setval('workspace_shift_definition_id_seq', 1, false);
SELECT setval('workspace_roster_assignment_id_seq', 1, false);
SELECT setval('workspace_team_role_group_rel_id_seq', 1, false);

-- ============================================
-- 1. 角色组 (Role Groups) - 5个组别
-- ============================================
INSERT INTO workspace_role_group (id, code, name, category, region, description, active, deleted, create_time, update_time)
VALUES
(1, 'L1', 'L1 Support', 'Support', 'Global', 'Level 1 Support Team - First line response', true, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(2, 'AP-L2', 'AP L2', 'Support', 'APAC', 'Asia Pacific Level 2 Support Team', true, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(3, 'UK-L2', 'UK L2', 'Support', 'EMEA', 'UK Level 2 Support Team', true, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(4, 'L3', 'L3 Support', 'Engineering', 'Global', 'Level 3 Support Team - Escalation engineers', true, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(5, 'MDP-L2', 'MDP L2', 'Support', 'Americas', 'MDP Level 2 Support Team', true, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- ============================================
-- 2. 团队 (Teams) - 5个团队对应5个角色组
-- ============================================
INSERT INTO workspace_team (id, team_code, name, color, display_order, visible, description, deleted, create_time, update_time)
VALUES
(1, 'L1', 'L1 Support Team', '#3B82F6', 1, true, 'First line support team handling initial customer requests', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(2, 'AP-L2', 'AP L2 Team', '#10B981', 2, true, 'Asia Pacific Level 2 support team', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(3, 'UK-L2', 'UK L2 Team', '#8B5CF6', 3, true, 'UK Level 2 support team', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(4, 'L3', 'L3 Support Team', '#F59E0B', 4, true, 'Level 3 escalation engineering team', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(5, 'MDP-L2', 'MDP L2 Team', '#EF4444', 5, true, 'MDP Level 2 support team', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- ============================================
-- 3. 团队与角色组关系
-- ============================================
INSERT INTO workspace_team_role_group_rel (id, team_id, role_group_id, create_time, update_time)
VALUES
(1, 1, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(2, 2, 2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(3, 3, 3, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(4, 4, 4, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(5, 5, 5, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- ============================================
-- 4. 员工 (Staff) - 每个团队4-5名员工
-- ============================================
-- L1 Team (6 members)
INSERT INTO workspace_staff (id, staff_code, name, email, phone, slack, region, timezone, role_name, role_group_id, status, avatar, notes, deleted, create_time, update_time)
VALUES
(1, 'L1-001', 'Alice Wang', 'alice.wang@company.com', '+86-138-0001-0001', '@alicewang', 'APAC', 'Asia/Shanghai', 'L1 Support Lead', 1, 'Active', NULL, 'Team lead for L1', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(2, 'L1-002', 'Bob Chen', 'bob.chen@company.com', '+86-138-0001-0002', '@bobchen', 'APAC', 'Asia/Shanghai', 'L1 Support Engineer', 1, 'Active', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(3, 'L1-003', 'Carol Liu', 'carol.liu@company.com', '+86-138-0001-0003', '@carolliu', 'APAC', 'Asia/Shanghai', 'L1 Support Engineer', 1, 'Active', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(4, 'L1-004', 'David Zhang', 'david.zhang@company.com', '+86-138-0001-0004', '@davidzhang', 'APAC', 'Asia/Shanghai', 'L1 Support Engineer', 1, 'Active', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(5, 'L1-005', 'Emma Li', 'emma.li@company.com', '+86-138-0001-0005', '@emmali', 'APAC', 'Asia/Shanghai', 'L1 Support Engineer', 1, 'Active', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(6, 'L1-006', 'Frank Wu', 'frank.wu@company.com', '+86-138-0001-0006', '@frankwu', 'APAC', 'Asia/Shanghai', 'L1 Support Engineer', 1, 'Active', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- AP L2 Team (5 members)
INSERT INTO workspace_staff (id, staff_code, name, email, phone, slack, region, timezone, role_name, role_group_id, status, avatar, notes, deleted, create_time, update_time)
VALUES
(7, 'APL2-001', 'Grace Tanaka', 'grace.tanaka@company.com', '+81-90-0002-0001', '@gracetanaka', 'APAC', 'Asia/Tokyo', 'AP L2 Lead', 2, 'Active', NULL, 'Team lead for AP L2', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(8, 'APL2-002', 'Henry Kim', 'henry.kim@company.com', '+82-10-0002-0002', '@henrykim', 'APAC', 'Asia/Seoul', 'AP L2 Engineer', 2, 'Active', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(9, 'APL2-003', 'Iris Singh', 'iris.singh@company.com', '+91-98-0002-0003', '@irissingh', 'APAC', 'Asia/Kolkata', 'AP L2 Engineer', 2, 'Active', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(10, 'APL2-004', 'Jack Nguyen', 'jack.nguyen@company.com', '+84-91-0002-0004', '@jacknguyen', 'APAC', 'Asia/Ho_Chi_Minh', 'AP L2 Engineer', 2, 'Active', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(11, 'APL2-005', 'Kate Wong', 'kate.wong@company.com', '+65-91-0002-0005', '@katewong', 'APAC', 'Asia/Singapore', 'AP L2 Engineer', 2, 'Active', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- UK L2 Team (5 members)
INSERT INTO workspace_staff (id, staff_code, name, email, phone, slack, region, timezone, role_name, role_group_id, status, avatar, notes, deleted, create_time, update_time)
VALUES
(12, 'UKL2-001', 'Liam Smith', 'liam.smith@company.com', '+44-79-0003-0001', '@liamsmith', 'EMEA', 'Europe/London', 'UK L2 Lead', 3, 'Active', NULL, 'Team lead for UK L2', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(13, 'UKL2-002', 'Mia Johnson', 'mia.johnson@company.com', '+44-79-0003-0002', '@miajohnson', 'EMEA', 'Europe/London', 'UK L2 Engineer', 3, 'Active', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(14, 'UKL2-003', 'Noah Williams', 'noah.williams@company.com', '+44-79-0003-0003', '@noahwilliams', 'EMEA', 'Europe/London', 'UK L2 Engineer', 3, 'Active', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(15, 'UKL2-004', 'Olivia Brown', 'olivia.brown@company.com', '+44-79-0003-0004', '@oliviabrown', 'EMEA', 'Europe/London', 'UK L2 Engineer', 3, 'Active', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(16, 'UKL2-005', 'Peter Taylor', 'peter.taylor@company.com', '+44-79-0003-0005', '@petertaylor', 'EMEA', 'Europe/London', 'UK L2 Engineer', 3, 'Active', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- L3 Team (4 members)
INSERT INTO workspace_staff (id, staff_code, name, email, phone, slack, region, timezone, role_name, role_group_id, status, avatar, notes, deleted, create_time, update_time)
VALUES
(17, 'L3-001', 'Quinn Martinez', 'quinn.martinez@company.com', '+1-555-0004-0001', '@quinnmartinez', 'Americas', 'America/New_York', 'L3 Lead Engineer', 4, 'Active', NULL, 'Team lead for L3', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(18, 'L3-002', 'Rachel Anderson', 'rachel.anderson@company.com', '+1-555-0004-0002', '@rachelanderson', 'Americas', 'America/Los_Angeles', 'L3 Engineer', 4, 'Active', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(19, 'L3-003', 'Sam Thomas', 'sam.thomas@company.com', '+1-555-0004-0003', '@samthomas', 'EMEA', 'Europe/Berlin', 'L3 Engineer', 4, 'Active', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(20, 'L3-004', 'Tina Garcia', 'tina.garcia@company.com', '+1-555-0004-0004', '@tinagarcia', 'Americas', 'America/Chicago', 'L3 Engineer', 4, 'Active', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- MDP L2 Team (5 members)
INSERT INTO workspace_staff (id, staff_code, name, email, phone, slack, region, timezone, role_name, role_group_id, status, avatar, notes, deleted, create_time, update_time)
VALUES
(21, 'MDP-001', 'Uma Rodriguez', 'uma.rodriguez@company.com', '+1-555-0005-0001', '@umarodriguez', 'Americas', 'America/New_York', 'MDP L2 Lead', 5, 'Active', NULL, 'Team lead for MDP L2', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(22, 'MDP-002', 'Victor Lee', 'victor.lee@company.com', '+1-555-0005-0002', '@victorlee', 'Americas', 'America/Los_Angeles', 'MDP L2 Engineer', 5, 'Active', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(23, 'MDP-003', 'Wendy Harris', 'wendy.harris@company.com', '+1-555-0005-0003', '@wendyharris', 'Americas', 'America/Denver', 'MDP L2 Engineer', 5, 'Active', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(24, 'MDP-004', 'Xavier Clark', 'xavier.clark@company.com', '+1-555-0005-0004', '@xavierclark', 'Americas', 'America/Chicago', 'MDP L2 Engineer', 5, 'Active', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(25, 'MDP-005', 'Yolanda Lewis', 'yolanda.lewis@company.com', '+1-555-0005-0005', '@yolandalewis', 'Americas', 'America/New_York', 'MDP L2 Engineer', 5, 'Active', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- ============================================
-- 5. 班次定义 (Shift Definitions)
-- ============================================
-- L1 Shifts
INSERT INTO workspace_shift_definition (id, role_group_id, code, meaning, start_time, end_time, timezone, primary_shift, visible, color_hex, remark, deleted, create_time, update_time)
VALUES
(1, 1, 'L1-D', 'L1 Day Shift', '09:00:00', '18:00:00', 'Asia/Shanghai', true, true, '#3B82F6', 'L1 Primary Day Shift', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(2, 1, 'L1-N', 'L1 Night Shift', '18:00:00', '09:00:00', 'Asia/Shanghai', false, true, '#1E40AF', 'L1 Night Shift', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(3, 1, 'L1-WD', 'L1 Weekend Day', '10:00:00', '18:00:00', 'Asia/Shanghai', false, true, '#60A5FA', 'L1 Weekend Day Shift', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- AP L2 Shifts
INSERT INTO workspace_shift_definition (id, role_group_id, code, meaning, start_time, end_time, timezone, primary_shift, visible, color_hex, remark, deleted, create_time, update_time)
VALUES
(4, 2, 'AP-D', 'AP Day Shift', '09:00:00', '18:00:00', 'Asia/Tokyo', true, true, '#10B981', 'AP L2 Primary Day Shift', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(5, 2, 'AP-E', 'AP Evening Shift', '14:00:00', '23:00:00', 'Asia/Tokyo', false, true, '#059669', 'AP L2 Evening Shift', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- UK L2 Shifts
INSERT INTO workspace_shift_definition (id, role_group_id, code, meaning, start_time, end_time, timezone, primary_shift, visible, color_hex, remark, deleted, create_time, update_time)
VALUES
(6, 3, 'UK-D', 'UK Day Shift', '09:00:00', '18:00:00', 'Europe/London', true, true, '#8B5CF6', 'UK L2 Primary Day Shift', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(7, 3, 'UK-E', 'UK Evening Shift', '14:00:00', '22:00:00', 'Europe/London', false, true, '#7C3AED', 'UK L2 Evening Shift', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- L3 Shifts
INSERT INTO workspace_shift_definition (id, role_group_id, code, meaning, start_time, end_time, timezone, primary_shift, visible, color_hex, remark, deleted, create_time, update_time)
VALUES
(8, 4, 'L3-D', 'L3 Day Shift', '09:00:00', '18:00:00', 'America/New_York', true, true, '#F59E0B', 'L3 Primary Day Shift', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(9, 4, 'L3-O', 'L3 On-Call', '18:00:00', '09:00:00', 'America/New_York', false, true, '#D97706', 'L3 On-Call Rotation', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- MDP L2 Shifts
INSERT INTO workspace_shift_definition (id, role_group_id, code, meaning, start_time, end_time, timezone, primary_shift, visible, color_hex, remark, deleted, create_time, update_time)
VALUES
(10, 5, 'MDP-D', 'MDP Day Shift', '09:00:00', '18:00:00', 'America/New_York', true, true, '#EF4444', 'MDP L2 Primary Day Shift', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(11, 5, 'MDP-E', 'MDP Evening Shift', '14:00:00', '22:00:00', 'America/New_York', false, true, '#DC2626', 'MDP L2 Evening Shift', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- ============================================
-- 6. 2026年3月排班数据 (March 2026 Roster)
-- ============================================

-- L1 Team - March 2026 Schedule (31 days)
-- Week 1 (Mar 1-7): Day shifts
INSERT INTO workspace_roster_assignment (id, staff_id, role_group_id, team_id, shift_definition_id, assignment_date, shift_code, source_type, notes, deleted, create_time, update_time)
VALUES
(1, 1, 1, 1, 1, '2026-03-01', 'L1-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(2, 2, 1, 1, 1, '2026-03-02', 'L1-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(3, 3, 1, 1, 1, '2026-03-03', 'L1-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(4, 4, 1, 1, 1, '2026-03-04', 'L1-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(5, 5, 1, 1, 1, '2026-03-05', 'L1-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(6, 6, 1, 1, 1, '2026-03-06', 'L1-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(7, 1, 1, 1, 3, '2026-03-07', 'L1-WD', 'MANUAL', 'Weekend coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- Week 2 (Mar 8-14)
(8, 2, 1, 1, 1, '2026-03-08', 'L1-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(9, 3, 1, 1, 1, '2026-03-09', 'L1-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(10, 4, 1, 1, 1, '2026-03-10', 'L1-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(11, 5, 1, 1, 1, '2026-03-11', 'L1-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(12, 6, 1, 1, 1, '2026-03-12', 'L1-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(13, 1, 1, 1, 1, '2026-03-13', 'L1-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(14, 2, 1, 1, 3, '2026-03-14', 'L1-WD', 'MANUAL', 'Weekend coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- Week 3 (Mar 15-21)
(15, 3, 1, 1, 1, '2026-03-15', 'L1-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(16, 4, 1, 1, 1, '2026-03-16', 'L1-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(17, 5, 1, 1, 1, '2026-03-17', 'L1-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(18, 6, 1, 1, 1, '2026-03-18', 'L1-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(19, 1, 1, 1, 1, '2026-03-19', 'L1-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(20, 2, 1, 1, 1, '2026-03-20', 'L1-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(21, 3, 1, 1, 3, '2026-03-21', 'L1-WD', 'MANUAL', 'Weekend coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- Week 4 (Mar 22-28)
(22, 4, 1, 1, 1, '2026-03-22', 'L1-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(23, 5, 1, 1, 1, '2026-03-23', 'L1-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(24, 6, 1, 1, 1, '2026-03-24', 'L1-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(25, 1, 1, 1, 1, '2026-03-25', 'L1-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(26, 2, 1, 1, 1, '2026-03-26', 'L1-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(27, 3, 1, 1, 1, '2026-03-27', 'L1-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(28, 4, 1, 1, 3, '2026-03-28', 'L1-WD', 'MANUAL', 'Weekend coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- Week 5 (Mar 29-31)
(29, 5, 1, 1, 1, '2026-03-29', 'L1-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(30, 6, 1, 1, 1, '2026-03-30', 'L1-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(31, 1, 1, 1, 1, '2026-03-31', 'L1-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- AP L2 Team - March 2026 Schedule
INSERT INTO workspace_roster_assignment (id, staff_id, role_group_id, team_id, shift_definition_id, assignment_date, shift_code, source_type, notes, deleted, create_time, update_time)
VALUES
-- Week 1
(32, 7, 2, 2, 4, '2026-03-01', 'AP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(33, 8, 2, 2, 4, '2026-03-02', 'AP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(34, 9, 2, 2, 4, '2026-03-03', 'AP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(35, 10, 2, 2, 4, '2026-03-04', 'AP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(36, 11, 2, 2, 4, '2026-03-05', 'AP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(37, 7, 2, 2, 5, '2026-03-06', 'AP-E', 'MANUAL', 'Evening coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(38, 8, 2, 2, 4, '2026-03-07', 'AP-D', 'MANUAL', 'Weekend coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- Week 2
(39, 9, 2, 2, 4, '2026-03-08', 'AP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(40, 10, 2, 2, 4, '2026-03-09', 'AP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(41, 11, 2, 2, 4, '2026-03-10', 'AP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(42, 7, 2, 2, 4, '2026-03-11', 'AP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(43, 8, 2, 2, 4, '2026-03-12', 'AP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(44, 9, 2, 2, 5, '2026-03-13', 'AP-E', 'MANUAL', 'Evening coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(45, 10, 2, 2, 4, '2026-03-14', 'AP-D', 'MANUAL', 'Weekend coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- Week 3
(46, 11, 2, 2, 4, '2026-03-15', 'AP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(47, 7, 2, 2, 4, '2026-03-16', 'AP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(48, 8, 2, 2, 4, '2026-03-17', 'AP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(49, 9, 2, 2, 4, '2026-03-18', 'AP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(50, 10, 2, 2, 4, '2026-03-19', 'AP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(51, 11, 2, 2, 5, '2026-03-20', 'AP-E', 'MANUAL', 'Evening coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(52, 7, 2, 2, 4, '2026-03-21', 'AP-D', 'MANUAL', 'Weekend coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- Week 4
(53, 8, 2, 2, 4, '2026-03-22', 'AP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(54, 9, 2, 2, 4, '2026-03-23', 'AP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(55, 10, 2, 2, 4, '2026-03-24', 'AP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(56, 11, 2, 2, 4, '2026-03-25', 'AP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(57, 7, 2, 2, 4, '2026-03-26', 'AP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(58, 8, 2, 2, 5, '2026-03-27', 'AP-E', 'MANUAL', 'Evening coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(59, 9, 2, 2, 4, '2026-03-28', 'AP-D', 'MANUAL', 'Weekend coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- Week 5
(60, 10, 2, 2, 4, '2026-03-29', 'AP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(61, 11, 2, 2, 4, '2026-03-30', 'AP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(62, 7, 2, 2, 4, '2026-03-31', 'AP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- UK L2 Team - March 2026 Schedule
INSERT INTO workspace_roster_assignment (id, staff_id, role_group_id, team_id, shift_definition_id, assignment_date, shift_code, source_type, notes, deleted, create_time, update_time)
VALUES
-- Week 1
(63, 12, 3, 3, 6, '2026-03-01', 'UK-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(64, 13, 3, 3, 6, '2026-03-02', 'UK-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(65, 14, 3, 3, 6, '2026-03-03', 'UK-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(66, 15, 3, 3, 6, '2026-03-04', 'UK-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(67, 16, 3, 3, 6, '2026-03-05', 'UK-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(68, 12, 3, 3, 7, '2026-03-06', 'UK-E', 'MANUAL', 'Evening coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(69, 13, 3, 3, 6, '2026-03-07', 'UK-D', 'MANUAL', 'Weekend coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- Week 2
(70, 14, 3, 3, 6, '2026-03-08', 'UK-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(71, 15, 3, 3, 6, '2026-03-09', 'UK-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(72, 16, 3, 3, 6, '2026-03-10', 'UK-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(73, 12, 3, 3, 6, '2026-03-11', 'UK-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(74, 13, 3, 3, 6, '2026-03-12', 'UK-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(75, 14, 3, 3, 7, '2026-03-13', 'UK-E', 'MANUAL', 'Evening coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(76, 15, 3, 3, 6, '2026-03-14', 'UK-D', 'MANUAL', 'Weekend coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- Week 3
(77, 16, 3, 3, 6, '2026-03-15', 'UK-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(78, 12, 3, 3, 6, '2026-03-16', 'UK-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(79, 13, 3, 3, 6, '2026-03-17', 'UK-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(80, 14, 3, 3, 6, '2026-03-18', 'UK-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(81, 15, 3, 3, 6, '2026-03-19', 'UK-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(82, 16, 3, 3, 7, '2026-03-20', 'UK-E', 'MANUAL', 'Evening coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(83, 12, 3, 3, 6, '2026-03-21', 'UK-D', 'MANUAL', 'Weekend coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- Week 4
(84, 13, 3, 3, 6, '2026-03-22', 'UK-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(85, 14, 3, 3, 6, '2026-03-23', 'UK-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(86, 15, 3, 3, 6, '2026-03-24', 'UK-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(87, 16, 3, 3, 6, '2026-03-25', 'UK-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(88, 12, 3, 3, 6, '2026-03-26', 'UK-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(89, 13, 3, 3, 7, '2026-03-27', 'UK-E', 'MANUAL', 'Evening coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(90, 14, 3, 3, 6, '2026-03-28', 'UK-D', 'MANUAL', 'Weekend coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- Week 5
(91, 15, 3, 3, 6, '2026-03-29', 'UK-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(92, 16, 3, 3, 6, '2026-03-30', 'UK-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(93, 12, 3, 3, 6, '2026-03-31', 'UK-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- L3 Team - March 2026 Schedule
INSERT INTO workspace_roster_assignment (id, staff_id, role_group_id, team_id, shift_definition_id, assignment_date, shift_code, source_type, notes, deleted, create_time, update_time)
VALUES
-- Week 1
(94, 17, 4, 4, 8, '2026-03-01', 'L3-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(95, 18, 4, 4, 8, '2026-03-02', 'L3-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(96, 19, 4, 4, 8, '2026-03-03', 'L3-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(97, 20, 4, 4, 8, '2026-03-04', 'L3-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(98, 17, 4, 4, 9, '2026-03-05', 'L3-O', 'MANUAL', 'On-call rotation', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(99, 18, 4, 4, 9, '2026-03-06', 'L3-O', 'MANUAL', 'On-call rotation', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(100, 19, 4, 4, 8, '2026-03-07', 'L3-D', 'MANUAL', 'Weekend coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- Week 2
(101, 20, 4, 4, 8, '2026-03-08', 'L3-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(102, 17, 4, 4, 8, '2026-03-09', 'L3-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(103, 18, 4, 4, 8, '2026-03-10', 'L3-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(104, 19, 4, 4, 8, '2026-03-11', 'L3-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(105, 20, 4, 4, 8, '2026-03-12', 'L3-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(106, 17, 4, 4, 9, '2026-03-13', 'L3-O', 'MANUAL', 'On-call rotation', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(107, 18, 4, 4, 8, '2026-03-14', 'L3-D', 'MANUAL', 'Weekend coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- Week 3
(108, 19, 4, 4, 8, '2026-03-15', 'L3-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(109, 20, 4, 4, 8, '2026-03-16', 'L3-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(110, 17, 4, 4, 8, '2026-03-17', 'L3-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(111, 18, 4, 4, 8, '2026-03-18', 'L3-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(112, 19, 4, 4, 8, '2026-03-19', 'L3-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(113, 20, 4, 4, 9, '2026-03-20', 'L3-O', 'MANUAL', 'On-call rotation', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(114, 17, 4, 4, 8, '2026-03-21', 'L3-D', 'MANUAL', 'Weekend coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- Week 4
(115, 18, 4, 4, 8, '2026-03-22', 'L3-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(116, 19, 4, 4, 8, '2026-03-23', 'L3-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(117, 20, 4, 4, 8, '2026-03-24', 'L3-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(118, 17, 4, 4, 8, '2026-03-25', 'L3-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(119, 18, 4, 4, 8, '2026-03-26', 'L3-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(120, 19, 4, 4, 9, '2026-03-27', 'L3-O', 'MANUAL', 'On-call rotation', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(121, 20, 4, 4, 8, '2026-03-28', 'L3-D', 'MANUAL', 'Weekend coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- Week 5
(122, 17, 4, 4, 8, '2026-03-29', 'L3-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(123, 18, 4, 4, 8, '2026-03-30', 'L3-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(124, 19, 4, 4, 8, '2026-03-31', 'L3-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- MDP L2 Team - March 2026 Schedule
INSERT INTO workspace_roster_assignment (id, staff_id, role_group_id, team_id, shift_definition_id, assignment_date, shift_code, source_type, notes, deleted, create_time, update_time)
VALUES
-- Week 1
(125, 21, 5, 5, 10, '2026-03-01', 'MDP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(126, 22, 5, 5, 10, '2026-03-02', 'MDP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(127, 23, 5, 5, 10, '2026-03-03', 'MDP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(128, 24, 5, 5, 10, '2026-03-04', 'MDP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(129, 25, 5, 5, 10, '2026-03-05', 'MDP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(130, 21, 5, 5, 11, '2026-03-06', 'MDP-E', 'MANUAL', 'Evening coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(131, 22, 5, 5, 10, '2026-03-07', 'MDP-D', 'MANUAL', 'Weekend coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- Week 2
(132, 23, 5, 5, 10, '2026-03-08', 'MDP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(133, 24, 5, 5, 10, '2026-03-09', 'MDP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(134, 25, 5, 5, 10, '2026-03-10', 'MDP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(135, 21, 5, 5, 10, '2026-03-11', 'MDP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(136, 22, 5, 5, 10, '2026-03-12', 'MDP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(137, 23, 5, 5, 11, '2026-03-13', 'MDP-E', 'MANUAL', 'Evening coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(138, 24, 5, 5, 10, '2026-03-14', 'MDP-D', 'MANUAL', 'Weekend coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- Week 3
(139, 25, 5, 5, 10, '2026-03-15', 'MDP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(140, 21, 5, 5, 10, '2026-03-16', 'MDP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(141, 22, 5, 5, 10, '2026-03-17', 'MDP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(142, 23, 5, 5, 10, '2026-03-18', 'MDP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(143, 24, 5, 5, 10, '2026-03-19', 'MDP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(144, 25, 5, 5, 11, '2026-03-20', 'MDP-E', 'MANUAL', 'Evening coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(145, 21, 5, 5, 10, '2026-03-21', 'MDP-D', 'MANUAL', 'Weekend coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- Week 4
(146, 22, 5, 5, 10, '2026-03-22', 'MDP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(147, 23, 5, 5, 10, '2026-03-23', 'MDP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(148, 24, 5, 5, 10, '2026-03-24', 'MDP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(149, 25, 5, 5, 10, '2026-03-25', 'MDP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(150, 21, 5, 5, 10, '2026-03-26', 'MDP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(151, 22, 5, 5, 11, '2026-03-27', 'MDP-E', 'MANUAL', 'Evening coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(152, 23, 5, 5, 10, '2026-03-28', 'MDP-D', 'MANUAL', 'Weekend coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- Week 5
(153, 24, 5, 5, 10, '2026-03-29', 'MDP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(154, 25, 5, 5, 10, '2026-03-30', 'MDP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(155, 21, 5, 5, 10, '2026-03-31', 'MDP-D', 'MANUAL', 'Primary coverage', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
