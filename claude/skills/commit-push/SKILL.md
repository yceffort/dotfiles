---
name: commit-push
description: 사용자가 "commit", "커밋해줘", "커밋 만들어줘" 등으로 명시적으로 git commit 생성을 요청할 때 사용. 변경사항을 검토하고 아토믹하게 나누어 커밋을 생성한다. 사용자가 요청하지 않은 상태에서 임의로 trigger하지 말 것.
model: haiku
---

현재 git 상태를 확인하고, 변경된 파일들을 검토한 후 적절한 커밋 메시지와 함께 커밋을 생성하라.

## 커밋 규칙

- 작업 범위를 최대한 작은 단위로 나눠서 아토믹하게 커밋할 것
- 커밋 메시지 앞에 적절한 이모지 붙이기
- 영어를 사용하여 한 줄로 간결하게 설명 (50자 이내 권장)
- "by Claude Code", "Co-Authored-By: Claude" 등 Claude 관련 문구를 절대 포함하지 말것

## Git Submodule 처리

git status에서 `modified: <submodule-name> (new commits)` 또는 서브모듈 변경이 감지되면:

1. **서브모듈 먼저 커밋/푸시**
   ```bash
   cd <submodule-name>
   git add -A
   git commit -m "커밋 메시지"
   git push origin main
   cd ..
   ```

2. **메인 저장소에서 서브모듈 참조 업데이트**
   ```bash
   git add <submodule-name>
   git commit -m "⬆️ Update <submodule-name> submodule: 변경내용 요약"
   git push origin main
   ```

**중요**: 서브모듈과 메인 저장소는 독립적인 커밋이 필요함. 반드시 2단계로 처리할 것.
