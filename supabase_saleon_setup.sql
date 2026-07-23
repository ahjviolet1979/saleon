-- SaleOn real storage setup for Supabase PostgreSQL
-- Run this in Supabase SQL Editor.

CREATE TABLE IF NOT EXISTS saleon_users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    login_id VARCHAR(60) NOT NULL UNIQUE,
    password_text VARCHAR(100) NOT NULL,
    user_name VARCHAR(100) NOT NULL,
    role_code VARCHAR(50) NOT NULL DEFAULT 'USER',
    status_text VARCHAR(50) NOT NULL DEFAULT '사용중',
    email VARCHAR(150),
    phone VARCHAR(30),
    temp_password VARCHAR(100),
    last_login_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS saleon_menus (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    menu_group VARCHAR(100) NOT NULL,
    menu_code VARCHAR(60) NOT NULL UNIQUE,
    menu_name VARCHAR(100) NOT NULL,
    menu_desc VARCHAR(500),
    icon_text VARCHAR(20),
    use_yn CHAR(1) NOT NULL DEFAULT 'Y',
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_saleon_menus_use_yn CHECK (use_yn IN ('Y', 'N'))
);

CREATE TABLE IF NOT EXISTS saleon_user_menu_permissions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    login_id VARCHAR(60) NOT NULL,
    menu_code VARCHAR(60) NOT NULL,
    can_view CHAR(1) NOT NULL DEFAULT 'Y',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_saleon_user_menu_permissions UNIQUE (login_id, menu_code),
    CONSTRAINT fk_saleon_user_menu_permissions_login_id
        FOREIGN KEY (login_id)
        REFERENCES saleon_users (login_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_saleon_user_menu_permissions_menu_code
        FOREIGN KEY (menu_code)
        REFERENCES saleon_menus (menu_code)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT chk_saleon_user_menu_permissions_can_view CHECK (can_view IN ('Y', 'N'))
);

ALTER TABLE saleon_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE saleon_menus ENABLE ROW LEVEL SECURITY;
ALTER TABLE saleon_user_menu_permissions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "saleon_users_public_demo_access" ON saleon_users;
DROP POLICY IF EXISTS "saleon_menus_public_demo_access" ON saleon_menus;
DROP POLICY IF EXISTS "saleon_user_menu_permissions_public_demo_access" ON saleon_user_menu_permissions;

-- Demo policy for prototype testing from GitHub Pages.
-- Replace this with real authentication policies before production.
CREATE POLICY "saleon_users_public_demo_access"
ON saleon_users
FOR ALL
USING (true)
WITH CHECK (true);

CREATE POLICY "saleon_menus_public_demo_access"
ON saleon_menus
FOR ALL
USING (true)
WITH CHECK (true);

CREATE POLICY "saleon_user_menu_permissions_public_demo_access"
ON saleon_user_menu_permissions
FOR ALL
USING (true)
WITH CHECK (true);

INSERT INTO saleon_users (
    login_id,
    password_text,
    user_name,
    role_code,
    status_text,
    last_login_at
) VALUES
    ('administrator', '1111', '관리자', 'ADMIN', '사용중', CURRENT_TIMESTAMP),
    ('user', '1111', '사용자', 'USER', '사용중', NULL)
ON CONFLICT (login_id) DO NOTHING;

INSERT INTO saleon_menus (
    menu_group,
    menu_code,
    menu_name,
    menu_desc,
    icon_text,
    sort_order
) VALUES
    ('시스템관리', 'USER_MANAGE', '사용자관리', '관리자가 사용자를 등록하고 메뉴 권한을 관리합니다.', '사', 10),
    ('시스템관리', 'MENU_MANAGE', '메뉴관리', '시스템 전체 메뉴를 등록하고 관리합니다.', '메', 20),
    ('시스템관리', 'USER_MENU_MANAGE', '사용자 ID별 메뉴관리', '사용자 ID마다 접근 가능한 메뉴를 관리합니다.', '권', 30),
    ('시스템관리', 'COMMON_CODE', '공통코드관리', '권한, 상태, 구분값 등 시스템 코드를 관리합니다.', '코', 40),
    ('사업장', 'PLACE_MANAGE', '사업장관리', '사용자가 소유한 여러 사업장을 등록하고 관리합니다.', '장', 50),
    ('기초관리', 'PARTNER_MANAGE', '거래처등록', '사업장별 거래처를 등록합니다.', '거', 60),
    ('기초관리', 'PRODUCT_MANAGE', '제품등록', '매입매출에 사용할 제품을 등록합니다.', '품', 70),
    ('거래관리', 'PURCHASE_MANAGE', '매입등록', '사업장별 매입 거래를 등록합니다.', '입', 80),
    ('거래관리', 'SALES_MANAGE', '매출등록', '사업장별 매출 거래를 등록합니다.', '출', 90),
    ('거래관리', 'MONEY_ENTRY', '입출금등록', '수금과 지급을 공통코드로 구분해 등록합니다.', '금', 100),
    ('현황/출력', 'TRADE_REPORT', '매입매출현황', '사업장별 또는 전체 사업장 통합 현황을 조회합니다.', '현', 110),
    ('현황/출력', 'STATEMENT_PRINT', '거래명세서 출력', '거래명세서를 출력합니다.', '명', 120),
    ('현황/출력', 'TRADE_TABLE_PRINT', '매입매출현황표 출력', '매입매출현황표를 출력합니다.', '표', 130),
    ('현황/출력', 'MONEY_REPORT_PRINT', '입출금현황 출력', '수금/지급 현황을 함께 출력합니다.', '출', 140)
ON CONFLICT (menu_code) DO UPDATE SET
    menu_group = EXCLUDED.menu_group,
    menu_name = EXCLUDED.menu_name,
    menu_desc = EXCLUDED.menu_desc,
    icon_text = EXCLUDED.icon_text,
    sort_order = EXCLUDED.sort_order,
    updated_at = CURRENT_TIMESTAMP;

INSERT INTO saleon_user_menu_permissions (
    login_id,
    menu_code,
    can_view
)
SELECT 'administrator', menu_code, 'Y'
FROM saleon_menus
WHERE menu_code IN ('USER_MANAGE', 'MENU_MANAGE', 'USER_MENU_MANAGE', 'COMMON_CODE')
ON CONFLICT (login_id, menu_code) DO NOTHING;

INSERT INTO saleon_user_menu_permissions (
    login_id,
    menu_code,
    can_view
)
SELECT 'user', menu_code, 'Y'
FROM saleon_menus
WHERE menu_code IN (
    'PLACE_MANAGE',
    'PARTNER_MANAGE',
    'PRODUCT_MANAGE',
    'PURCHASE_MANAGE',
    'SALES_MANAGE',
    'MONEY_ENTRY',
    'TRADE_REPORT',
    'STATEMENT_PRINT',
    'TRADE_TABLE_PRINT',
    'MONEY_REPORT_PRINT'
)
ON CONFLICT (login_id, menu_code) DO NOTHING;
