#!/usr/bin/env node
// 한국어 글 문체 스캔. 문장 단위 체크리스트가 못 보는 문서 단위 빈도와 구간별 밀도를 센다.
// 사용: node scan.mjs <file.md> [file2.md ...]
import {readFileSync} from 'node:fs'

const PER = 10_000 // 밀도 단위: 공백 제외 10,000자당

// 즉시 수정: 한 건이라도 나오면 고친다
const HARD = [
  {id: 'em-dash', label: 'em dash(—)/en dash(–)', re: /[—–]/g},
  {id: 'middot', label: '가운뎃점(·)', re: /·/g},
  {id: 'emoji', label: '본문 이모지', re: /\p{Extended_Pictographic}/gu},
  {id: 'tilde', label: '이중 이스케이프 물결(\\~\\~, 렌더 시 ~~)', re: /\\~\\~/g},
  {id: 'banned', label: '금지어(처방/층위/값어치)', re: /처방|층위|값어치/g},
  {id: 'hanja', label: '한자 병기', re: /\([一-鿿]+\)/g},
]

// 축자 번역과 사제 은유 후보. 영어 원문이 떠오르면 축자 번역이다
const LITERAL = [
  {id: 'arms', label: '팔(arms, 실험 조건)', re: /양쪽 팔|한쪽 팔|두 팔/g},
  {id: 'peak', label: '봉(peak, 분포의 무리)', re: /(?<!이)봉(?!분포|우리|투|쇄|사)/g},
  {id: 'copy', label: '한 벌/한 부(a copy)', re: /한 벌|한 부(?=[를을이가 ])/g},
  {id: 'ruler', label: '자(ruler, 잣대)', re: /다른 자(였|다|이)/g},
  {id: 'wire', label: '걷어 내다/흘려보내다(off the wire)', re: /걷어 ?내|흘려보내/g},
  {id: 'serve', label: '내주다(serve)', re: /내주|내준|내줬/g},
  {id: 'stand-on', label: '위에 서 있다(rests on)', re: /위에 서 있/g},
  {id: 'honest', label: '정직한 확인/검증(honest check)', re: /정직한 (확인|검증|평가|비교)/g},
  {id: 'about', label: '~에 대해(about)', re: /에 대해서?도?/g},
  {id: 'accounting', label: '계상(→집계)', re: /(?<![설합])계상/g},
  {id: 'pacing', label: '페이싱(pacing→속도 조절)', re: /페이싱/g},
]

// 반복 틀: 문서 전체 빈도와 구간별 밀도를 본다
const TICS = [
  {id: 'not-but', label: 'A가 아니라 B', re: /[가이] 아니라/g, ref: 8},
  {id: 'side', label: '~쪽', re: /쪽/g, ref: 8},
  {id: 'read', label: '~로 읽다(해석하다)', re: /[으]?로 읽|읽어야|읽으면|읽힌|읽힐|읽게 되|읽는 편|읽기는/g, ref: 3},
  {id: 'sem', label: '~셈이다/~뜻이다', re: /셈이|뜻이|뜻인/g, ref: 8},
  {id: 'so', label: '그러니까(동격)', re: /그러니까/g, ref: 0},
  {id: 'right', label: '~것이 맞다/편이 맞다', re: /것이 맞|편이 맞/g, ref: 1.5},
  {id: 'this-side', label: '이쪽/그쪽/저쪽', re: /[이그저]쪽/g, ref: 0.5},
  {id: 'share', label: '몫', re: /몫/g, ref: 2},
]

// 무생물 주어 + 행위 동사: "2편이 밝히고", "데이터도 같은 말을 한다", "랩은 찾지 못했다"
const AGENT_SUBJ =
  /(\d편|이 편|그 편|랩|데이터|표|측정|시리즈|결과|절|줄|행|발견|조건|단서)(이|가|은|는|도) [^.\n]{0,40}?(밝히|넘겼|넘긴|꼽|짚|찾지|찾아|확정|알려 ?줬|같은 말|보여준|보여 준|판 것|남긴|가리키|주는 답|재지 못|말할 수 있|접었|바꾼다)/g

// 경구형 마무리: 문단 끝의 10자 이하 단문, 또는 어디서든 4자 이하 체언+이다("기각이다", "추정이다")
const APHORISM_END = /(?:^|[.!?] )([^.!?\n]{1,10}(?:이다|다)\.)[ \t]*$/gm
const APHORISM_NOUN = /(?:^|[.!?] )([가-힣A-Za-z]{1,4}이다\.)/gm
const APHORISM_SKIP = /다음과 같|이렇다|그렇다|정리하면|우선 |다음으로|마지막으로|첫째|둘째|셋째/
const FRAGMENT = /(?:^|[.!?] )([^.!?\n]{1,14}(?:것|일|이유|이야기)\.)(?= |$)/gm

// 순우리말 수사: 측정치는 아라비아 숫자로. "세 가지", "한 번"은 허용
const NUMERAL =
  /(?:열[한두세네다섯여섯일곱여덟아홉]?|스물|서른|마흔|쉰|예순)(?:다섯|여섯|일곱|여덟|아홉)?\s?(?:회|쌍|건|번|개|명|장|줄)|(?<![가-힣])(?:둘|셋|넷|다섯|여섯|일곱|여덟|아홉)(?:이다|이었|이었|이|을|뿐|만)(?![가-힣])|넉 ?장|넉 ?개|석 ?장/g

// 집필 과정 노출: 정정은 본문을 고쳐서 반영한다
const DRAFT_TRACE =
  /처음에는 [^.\n]{0,40}적었는데|뒤에 철회하게|철회하게 된다|세 번째로 같은 함정|고백해|나는 [^.\n]{0,20}밟았다|또 밟았다|써 놓은 뒤에 알았|쓰고 나서야|다 쓰고도/g

const PARA_MAX = 700

function stripCode(text) {
  // 코드 블록은 줄 수를 유지한 채 비운다
  return text.replace(/```[\s\S]*?```/g, (m) => m.replace(/[^\n]/g, ' '))
}

function stripFrontmatter(text) {
  return text.replace(/^---[\s\S]*?\n---\n/, (m) => m.replace(/[^\n]/g, ' '))
}

function chars(s) {
  return s.replace(/\s/g, '').length
}

function lineOf(text, idx) {
  return text.slice(0, idx).split('\n').length
}

function ctx(text, idx, len, span = 14) {
  const a = Math.max(0, idx - span)
  const b = Math.min(text.length, idx + len + span)
  return text.slice(a, b).replace(/\n/g, ' ')
}

function hits(text, re) {
  const out = []
  re.lastIndex = 0
  for (const m of text.matchAll(re)) out.push({idx: m.index, len: m[0].length, s: m[0]})
  return out
}

function sections(text) {
  const lines = text.split('\n')
  const out = []
  let cur = {title: '(서론)', start: 1, lines: []}
  lines.forEach((l, i) => {
    if (/^## /.test(l)) {
      out.push(cur)
      cur = {title: l.replace(/^## /, ''), start: i + 1, lines: []}
    }
    cur.lines.push(l)
  })
  out.push(cur)
  return out.map((s) => ({...s, body: s.lines.join('\n'), chars: chars(s.lines.join('\n'))})).filter((s) => s.chars > 0 && s.title !== 'Table of Contents')
}

function report(file) {
  const raw = readFileSync(file, 'utf8')
  const text = stripCode(stripFrontmatter(raw))
  const total = chars(text)
  const secs = sections(text)
  const lines = []
  const p = (s = '') => lines.push(s)

  p(`# ${file}`)
  p(`본문 ${total.toLocaleString()}자(공백, 코드, frontmatter 제외), 구간 ${secs.length}개`)

  // 1. 즉시 수정
  p('\n## 1. 즉시 수정')
  let any = false
  for (const {label, re} of HARD) {
    const h = hits(text, re)
    if (!h.length) continue
    any = true
    p(`- ${label}: ${h.length}건  ${h.slice(0, 8).map((x) => `L${lineOf(text, x.idx)}`).join(' ')}${h.length > 8 ? ' …' : ''}`)
  }
  if (!any) p('- 없음')

  // 2. 축자 번역/은유
  p('\n## 2. 축자 번역, 사제 은유 후보 (영어 원문이 떠오르면 축자 번역. 3회 이상이면 용어가 된 것)')
  any = false
  for (const {label, re} of LITERAL) {
    const h = hits(text, re)
    if (!h.length) continue
    any = true
    p(`- ${label}: ${h.length}건  ${h.slice(0, 6).map((x) => `L${lineOf(text, x.idx)} "${ctx(text, x.idx, x.len, 8)}"`).join(' | ')}${h.length > 6 ? ' …' : ''}`)
  }
  if (!any) p('- 없음')

  // 3. 반복 틀
  p('\n## 3. 반복 틀 (10,000자당 밀도. 기준은 SW 시리즈 1~2편 실측)')
  p('| 패턴 | 건수 | 밀도 | 기준 | 판정 |')
  p('| --- | ---: | ---: | ---: | --- |')
  const ticHits = {}
  for (const {id, label, re, ref} of TICS) {
    const h = hits(text, re)
    ticHits[id] = h
    const d = (h.length / total) * PER
    const flag = d > ref * 1.5 ? '초과' : d > ref ? '경계' : ''
    p(`| ${label} | ${h.length} | ${d.toFixed(1)} | ${ref} | ${flag} |`)
  }

  // 구간별 밀도: 어느 구간이 튀는지
  p('\n### 구간별 밀도 (반복 틀 합산, 10,000자당. 중앙값의 1.5배를 넘는 구간에 *)')
  const secDensity = secs.map((s) => {
    const n = TICS.reduce((acc, {re}) => acc + hits(s.body, re).length, 0)
    return {title: s.title, start: s.start, chars: s.chars, d: (n / s.chars) * PER, n}
  })
  const sorted = [...secDensity].map((x) => x.d).sort((a, b) => a - b)
  const median = sorted[Math.floor(sorted.length / 2)] ?? 0
  p('| 구간 | 시작줄 | 글자 | 건수 | 밀도 |')
  p('| --- | ---: | ---: | ---: | ---: |')
  for (const s of secDensity) {
    p(`| ${s.title} | ${s.start} | ${s.chars.toLocaleString()} | ${s.n} | ${s.d.toFixed(0)}${s.d > median * 1.5 && s.chars > 800 ? ' *' : ''} |`)
  }

  // 4. 무생물 주어
  const agent = hits(text, AGENT_SUBJ)
  p(`\n## 4. 무생물 주어 + 행위 동사: ${agent.length}건 (N편이 밝히다, 데이터가 말하다 → "N편에서", "데이터로도 확인된다")`)
  for (const x of agent.slice(0, 20)) p(`- L${lineOf(text, x.idx)} "${x.s}"`)
  if (agent.length > 20) p(`- … 외 ${agent.length - 20}건`)

  // 5. 경구형 마무리
  const seen = new Set()
  const aph = [...hits(text, APHORISM_END), ...hits(text, APHORISM_NOUN)]
    .filter((x) => !APHORISM_SKIP.test(x.s))
    .filter((x) => !seen.has(x.idx) && seen.add(x.idx))
    .sort((a, b) => a.idx - b.idx)
  const frag = hits(text, FRAGMENT)
  p(`\n## 5. 경구형 한 문장 마무리: ${aph.length}건 (글당 2~3회까지), 명사구 단독 문장: ${frag.length}건`)
  for (const x of aph) p(`- L${lineOf(text, x.idx)} "${x.s.trim()}"`)
  for (const x of frag) p(`- L${lineOf(text, x.idx)} "${x.s.trim()}" (명사구)`)

  // 6. 수사
  const num = hits(text, NUMERAL)
  p(`\n## 6. 순우리말 수사: ${num.length}건 (측정치는 아라비아 숫자, 표와 본문 표기 일치. "세 가지", "한 번"은 예외)`)
  for (const x of num.slice(0, 20)) p(`- L${lineOf(text, x.idx)} "${ctx(text, x.idx, x.len, 6)}"`)
  if (num.length > 20) p(`- … 외 ${num.length - 20}건`)

  // 7. 집필 과정 노출
  const dr = hits(text, DRAFT_TRACE)
  p(`\n## 7. 집필 과정 노출: ${dr.length}건 (정정은 본문을 고쳐서 반영. 서사로 남길 실수는 글당 1건)`)
  for (const x of dr) p(`- L${lineOf(text, x.idx)} "${ctx(text, x.idx, x.len, 10)}"`)

  // 8. 긴 문단
  const longParas = []
  let line = 1
  for (const para of text.split(/\n\n+/)) {
    const c = chars(para)
    if (c > PARA_MAX && !/^\||^!\[|^\[\^/.test(para.trim())) longParas.push({line, c})
    line += para.split('\n').length + 1
  }
  p(`\n## 8. ${PARA_MAX}자 넘는 문단: ${longParas.length}건`)
  for (const x of longParas) p(`- L${x.line} (${x.c}자)`)

  return lines.join('\n')
}

const files = process.argv.slice(2)
if (!files.length) {
  console.error('usage: node scan.mjs <file.md> [more.md ...]')
  process.exit(2)
}
console.log(files.map(report).join('\n\n---\n\n'))
