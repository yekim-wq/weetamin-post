# 위타민 우체국 — 실제 페이지 배포 가이드

GitHub Pages(페이지 호스팅)와 Supabase(편지 저장)를 연결해서 실제 이벤트 페이지로 여는 방법이에요. 두 서비스 모두 무료 요금제로 시작할 수 있어요.

## 파일 구성

| 파일 | 역할 | GitHub에 올리나요? |
|---|---|---|
| `index.html` | 이벤트 페이지 전체 | 올려요 |
| `config.js` | Supabase 주소·공개 키 | 올려요 (2단계에서 값을 채운 뒤) |
| `fonts/ssronet-hand.woff2` | 손글씨 폰트 (선택) | 파일이 있으면 올려요 |
| `supabase.sql` | Supabase 설정용 SQL | 올리지 않아도 돼요 |

---

## 1단계. Supabase 프로젝트 만들기

1. https://supabase.com 에 가입하고 **New project**를 눌러요.
   - Region은 **Northeast Asia (Seoul)**을 고르세요.
   - Database password는 따로 잘 보관해 두세요.
2. 프로젝트가 만들어지면 왼쪽 메뉴의 **SQL Editor** → **New query**를 눌러요.
3. `supabase.sql` 내용을 전부 붙여넣고 **Run**을 눌러요. "Success"가 뜨면 끝이에요.
   - 편지 테이블(`letters`)과 보안 설정, 편지 쓰기·읽기·하트 기능이 한 번에 만들어져요.
   - 방문자는 테이블에 직접 접근할 수 없고, 정해진 기능으로만 편지를 쓰고 읽을 수 있어요.

## 2단계. config.js 채우기

1. Supabase 대시보드 상단의 **Connect** 버튼(또는 **Project Settings → API Keys**)으로 들어가요.
2. 아래 두 값을 복사해서 `config.js`에 붙여넣어요.
   - **Project URL** → `SUPABASE_URL` (예: `https://abcdefgh.supabase.co`)
   - **anon public** 키 또는 **publishable** 키 → `SUPABASE_ANON_KEY`
3. ⚠️ `service_role` / `secret` 키는 절대 넣지 마세요. 이 키가 공개되면 누구나 DB 전체를 지울 수 있어요.

```js
window.WEETAMIN_CONFIG = {
  SUPABASE_URL: "https://abcdefgh.supabase.co",
  SUPABASE_ANON_KEY: "eyJhbGciOi..."
};
```

## 3단계. GitHub에 올리고 Pages 켜기

1. https://github.com 에서 **New repository**를 만들어요.
   - 이름 예: `weetamin-post`
   - **Public**으로 만드세요. 무료 계정의 GitHub Pages는 공개 저장소에서만 돼요.
2. 저장소 화면에서 **Add file → Upload files**를 누르고 `index.html`, `config.js`를 끌어다 놓아요. 폰트 파일이 있으면 `fonts` 폴더째 올려요.
3. **Commit changes**를 눌러요.
4. **Settings → Pages**로 가서 아래처럼 설정하고 **Save**를 눌러요.
   - Source: **Deploy from a branch**
   - Branch: **main** / **/(root)**
5. 1~2분 뒤 같은 화면 위쪽에 주소가 떠요. 예: `https://<깃허브아이디>.github.io/weetamin-post/`

## 4단계. 동작 확인

1. 핸드폰과 PC에서 페이지를 열어 편지를 한 통 보내 보세요.
2. Supabase **Table Editor → letters**에 편지가 한 줄 생겼는지 확인해요.
3. 공유 링크(`…/#letter-8자리ID`)를 다른 기기에서 열어 편지가 도착하는지 봐요.
4. 편지 벽에 새 편지가 보이는지, 하트를 누르면 숫자가 저장되는지 확인해요(새로고침 후에도 유지).

---

## 이렇게 동작해요

- **편지 보내기:** 서버에 저장되고, 짧은 링크(`#letter-Ab3xK9mQ`)가 만들어져요. 서버 연결에 실패하면 편지 내용을 링크 안에 담은 긴 링크로 자동 전환돼요.
- **편지 벽:** "편지 벽에 공개하기"를 선택한 편지만 최신순으로 40개까지 보여요. 보내는 사람 이름은 편지 벽에 나오지 않아요.
- **받는 화면:** 비공개 편지도 링크를 가진 사람은 열 수 있어요.
- **접수 수:** 숨김 처리하지 않은 모든 편지(비공개 포함)를 세요.
- **하트:** 같은 브라우저에서는 한 번만 누를 수 있게 기억해요.

## 운영 팁 (Supabase SQL Editor에서 실행)

```sql
-- 하트 많은 편지 TOP 10 (선물 대상 고르기)
select id, to_name, message, from_name, hearts, created_at
from letters where not hidden order by hearts desc limit 10;

-- 부적절한 편지 숨기기 (편지 벽·링크 모두에서 사라짐)
update letters set hidden = true where id = '편지ID';

-- 전체 편지 내보내기: Table Editor → letters → 우측 상단 Export → CSV
```

## 알아두면 좋은 점

- **하트·스팸 방지는 간단한 수준이에요.** 하트 중복은 브라우저 기준으로만 막아서, 마음먹고 반복 호출하면 숫자를 올릴 수 있어요. 하트 수로 경품을 준다면 당첨 전에 TOP 편지를 한 번 눈으로 확인하세요.
- **손글씨 폰트:** `fonts/ssronet-hand.woff2`가 없으면 구글 '나눔펜' 폰트로 자동 대체돼요. 상업적 이벤트에 쓰기 전에 폰트 라이선스를 확인하세요.
- **카카오톡 미리보기:** 링크를 공유하면 제목·설명이 나와요. 썸네일 이미지를 넣으려면 1200×630 이미지를 올리고 `index.html`의 `<head>`에 `<meta property="og:image" content="이미지 주소">`를 추가하세요.
- **수정할 때:** GitHub 저장소에서 파일을 다시 올리면 1~2분 뒤 사이트에 반영돼요.
- **Supabase 무료 요금제:** 7일 동안 접속이 없으면 프로젝트가 일시 정지돼요. 이벤트 기간에는 문제없지만, 시작 전에 미리 한 번 열어 두세요.
