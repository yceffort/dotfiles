---
name: changeset
description: 사용자가 "changeset 만들어줘", "changeset 생성", "버전 bump" 등으로 명시적으로 changeset 파일 생성을 요청할 때 사용. 변경사항을 분석해 .changeset/ 디렉토리에 파일을 만든다. 사용자가 요청하지 않은 상태에서 임의로 trigger하지 말 것.
---

현재 브랜치의 변경사항을 분석하여 적절한 changeset 파일을 `.changeset/` 디렉토리에 생성하라. 사용자의 추가 컨텍스트가 있으면 그것을 반영한다.

## 분석 단계

1. `.changeset/config.json`에서 `baseBranch`와 `ignore` 목록 확인
2. `git diff <baseBranch>...HEAD`로 변경된 파일과 내용 파악
3. 변경된 파일을 패키지 단위로 그룹핑 (`packages/<name>`, `apps/<name>`)
4. 각 패키지의 `package.json`에서 `name`, `private` 필드 확인
5. 다음에 해당하는 패키지는 제외:
   - `private: true` 패키지
   - `.changeset/config.json`의 `ignore` 목록에 포함된 패키지
6. 남은 패키지가 없으면 안내 메시지를 출력하고 종료

## Bump Type 추천 기준

각 패키지에 대해 diff를 분석하여 bump type을 추천하라.

- **major**: breaking change
  - public API의 export 제거
  - 함수/타입 시그니처 변경 (파라미터 추가·순서 변경·타입 변경)
  - 기존 동작의 의미가 변하는 변경
- **minor**: 새로운 기능, 새 export, 새 패키지
  - 새 함수·타입·컴포넌트 export 추가
  - 새 옵션 필드 추가 (기본값으로 기존 동작 유지)
  - 패키지 자체의 첫 추가
- **patch**: 버그 수정, 내부 리팩토링
  - public surface가 변하지 않는 내부 변경
  - 버그 수정, 문서·주석 변경, 의존성 업데이트

사용자가 힌트(예: "patch", "breaking 있음", "단순 리팩토링")를 주면 추천에 반영하라.

## 사용자 확인 (필수)

분석이 끝나면 다음을 사용자에게 보여주고 **반드시 명시적인 승인을 받을 것**:

1. 변경된 패키지 목록 (제외된 패키지가 있으면 그 사유도 함께)
2. 각 패키지에 대한 추천 bump type과 그 근거를 한 줄로
3. 사용자가 bump type을 변경하거나, 패키지를 제외/추가할 수 있도록 안내
4. **사용자가 승인하기 전까지 파일을 생성하지 말 것**

최종 결정권은 작성자(사용자)에게 있다. AI는 추천만 하고, 최종 선택은 작성자가 한다.

## Changeset 파일 작성 규칙

- 변경된 패키지마다 **별도 파일** 생성 (한 파일에 여러 패키지를 묶지 말 것)
- 파일명: `.changeset/<verb>-<short-description>.md` (kebab-case, 영어)
- frontmatter 형식:
  ```
  ---
  '<package-name>': <bump-type>
  ---
  ```
- 본문은 **한국어로 작성**:
  - 첫 단락: 변경의 핵심을 1-2 문장으로 요약
  - 이후: 주요 변경사항을 `### 섹션 제목`으로 나눠 상세 설명
  - breaking change가 있으면 **마이그레이션** 가이드 섹션 포함
  - 코드 예시는 ```ts 코드 블록 사용
  - 패키지·함수·타입·옵션 이름은 백틱(\`) 처리
- 작성 전에 `.changeset/`에 기존 changeset 파일이 있다면 1-2개 읽어보고 본문 톤·구조를 맞출 것

## 작성 후

- 생성된 파일 경로를 사용자에게 알려줄 것
- 본문에는 추측이 들어갔을 수 있으므로 사용자가 직접 검토하도록 권할 것
- 커밋은 별도 단계 — 사용자에게 커밋 요청을 권할 것
