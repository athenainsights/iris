# Guide: encoding the Pew ATP Wave 173 toplines and crosstabs

This guide walks through turning the Pew toplines and crosstabs in [results.md](results.md) into the Iris instance in [instance.json](instance.json). Each section takes one question from the results file, names the parts of the schema it touches, and shows the JSON to add to a growing skeleton. By the end you have the full instance.

The order follows the results file. Each question introduces whatever schema features it needs and nothing more, so later questions lean on vocabulary the earlier ones installed.

**Notation.** ALLCAPS names like `AI_HEARD` refer to Pew's questionnaire tags as they appear in the topline; `lowercase_ids` in backticks like `ai_heard` are the corresponding identifiers in our Iris instance. The two name the same question at different stages: what Pew published versus what we encoded.

## The skeleton

Every Iris instance starts with the same small shell. The root needs a version marker, a study id, a publisher, at least one question, and at least one wave. Everything else fills in as the topline demands it.

```json
{
  "schema_version": "dev",
  "study_id": "pew-atp-w173",
  "title": "Pew ATP Wave 173 - AI and its impact",
  "publisher": {
    "display_name": "Pew Research Center",
    "url": "https://www.pewresearch.org/",
    "roles": ["pollster", "publisher"]
  },
  "methodology_notes": "…",
  "subgroup_schema": { "variables": [] },
  "questions": [],
  "waves": []
}
```

`methodology_notes` carries the preamble Pew prints at the top of the PDF: panel description, fielding mode, the "<1" rounding convention, the rule for what "No answer" absorbs in each question. Settle those details here once.

`subgroup_schema` starts empty. We will add one variable, the form-assignment randomizer, when the first question that needs it appears.

### Waves

The topline carries trend rows going back to 2021, so the instance needs five waves: Wave 173 itself plus four earlier waves that contribute prior comparison numbers. Set up all five wave shells now; later questions fill in results.

Wave 173 is the primary wave. It carries the sample methodology that applies to every result in the wave, so fill it in up front:

```json
{
  "wave_id": "w173",
  "label": "Wave 173 - June 2025",
  "field_dates": { "start": "2025-06-09", "end": "2025-06-15" },
  "sample": {
    "population": "U.S. adults 18+",
    "n": 5023,
    "mode": ["online", "phone_cell", "phone_landline"],
    "frame": "probability_panel",
    "margin_of_error": 1.6,
    "weighting": {
      "scheme": "raking",
      "notes": "Weights raked to Pew's standard ATP benchmarks."
    }
  },
  "subgroups": [],
  "results": []
}
```

The four earlier waves are trend references. They exist so trend rows from the topline can be read as a single series. From the topline alone we know the date range and the reported percentages; we do not know the sample size, mode, or weighting targets for those earlier waves.

Iris allows that. `sample` is a RECOMMENDED field, not a required one, so a trend-reference wave may legitimately leave it off. `iris-lint` flags the absence as a warning, not an error, and those stubs pass validation. When the authoritative methodology later becomes available, it can be filled in without breaking anything.

A stub wave carries only what the topline tells us: an id, a label, field dates, and an empty results array:

```json
{
  "wave_id": "trend_2024-08",
  "label": "August 2024 - trend reference",
  "field_dates": { "start": "2024-08-12", "end": "2024-08-18" },
  "results": []
},
{
  "wave_id": "trend_2023-07",
  "label": "July-August 2023 - trend reference",
  "field_dates": { "start": "2023-07-31", "end": "2023-08-06" },
  "results": []
},
{
  "wave_id": "trend_2022-12",
  "label": "December 2022 - trend reference",
  "field_dates": { "start": "2022-12-12", "end": "2022-12-18" },
  "results": []
},
{
  "wave_id": "trend_2021-11",
  "label": "November 2021 - trend reference (CNCEXC wording variant)",
  "field_dates": { "start": "2021-11-01", "end": "2021-11-07" },
  "results": []
}
```

With the five waves in place, we walk the topline.

## AI_HEARD: a single-item ordered scale

The topline opens with this. A stem defines AI and asks how much the respondent has heard. Three substantive options plus a "No answer" catcher for blanks and phone refusals. Trend rows go back to Dec 2022, so this question contributes to four of our five waves.

This is the simplest shape in Iris. One dimension carries the full wording. The response space is an ordered enum with three substantive codes and one missing code.

Add to `questions`:

```json
{
  "id": "ai_heard",
  "stem": "",
  "dimensions": [
    {
      "id": "main",
      "text": "Artificial intelligence (AI) is designed to learn tasks that humans typically do, for instance recognizing speech or pictures. How much have you heard or read about AI?"
    }
  ],
  "response_space": {
    "kind": "enum",
    "ordered": true,
    "codes": [
      { "code": 1, "label": "A lot", "value": 2 },
      { "code": 2, "label": "A little", "value": 1 },
      { "code": 3, "label": "Nothing at all", "value": 0 },
      { "code": 99, "label": "No answer", "missing": true, "missing_kind": "skipped" }
    ]
  }
}
```

Three choices to note:

- **Stem versus dimension text.** For a single-item question, Iris puts the full wording in the dimension's `text` and leaves `stem` empty. Matrices use `stem` for the shared prefix; single-item questions have no prefix to share.
- **Ordered enum.** `ordered: true` tells consumers the codes form a continuum. The `value` hint maps each code to a numeric scale for downstream averaging.
- **Missing code.** "No answer" gets `missing: true` so consumers can strip it when computing an "answered" base; `missing_kind: "skipped"` captures that it blends web skips and phone refusals (no "Not sure" was offered on this question).

### Results across four waves

The Wave 173 result goes into `waves[0].results`:

```json
{
  "question_id": "ai_heard",
  "dimension_id": "main",
  "base": { "kind": "all", "n_unweighted": 5023 },
  "distribution": {
    "kind": "categorical",
    "entries": [
      { "code": 1, "pct": 47 },
      { "code": 2, "pct": 48 },
      { "code": 3, "pct": 5 },
      { "code": 99, "pct": 1 }
    ]
  }
}
```

`base.kind` is `"all"` because Pew prints the "No answer" percentage alongside the substantive ones; both sit in the denominator. The "<1" in the topline becomes `1` per our rendering convention. `subgroup_id` is absent, so the result is implicitly for the full sample.

Each earlier wave gets its own result entry, sitting in that wave's `results` array. The shape matches the Wave 173 result with two changes: the percentages come from the corresponding trend row, and `base.n_unweighted` is omitted because the stub wave's total sample size is not in the topline.

The August 2024 result goes into `waves[1].results`:

```json
{
  "question_id": "ai_heard",
  "dimension_id": "main",
  "base": { "kind": "all" },
  "distribution": {
    "kind": "categorical",
    "entries": [
      { "code": 1, "pct": 40 },
      { "code": 2, "pct": 53 },
      { "code": 3, "pct": 6 },
      { "code": 99, "pct": 1 }
    ]
  }
}
```

The 2023 (`waves[2]`) and 2022 (`waves[3]`) results follow the same pattern with percentages from the topline. The 2021 wave (`waves[4]`) gets no AI_HEARD result; Pew's AI_HEARD trend only goes back to 2022.

A consumer deriving the AI_HEARD trend line groups results on `question_id = "ai_heard"` and orders by wave `field_dates.start`. That gives the four-wave series the topline prints.

## CNCEXC: a nominal forced choice

CNCEXC offers three mutually exclusive options with no natural order: more excited, more concerned, or equally both. Same skeleton as `ai_heard`, with two differences: `ordered: false`, and each code carries a `pole` hint instead of a `value`.

The trend goes back to Nov 2021, where Pew used a different stem. We handle the 2022-2025 results first, then address the 2021 wording change.

```json
{
  "id": "cncexc",
  "stem": "",
  "concept_refs": [{ "scheme": "local", "id": "cncexc" }],
  "notes": "Rotation: options 1-2/2-1 with option 3 always held last.",
  "dimensions": [
    {
      "id": "main",
      "text": "Overall, would you say the increased use of artificial intelligence (AI) in daily life makes you feel…"
    }
  ],
  "response_space": {
    "kind": "enum",
    "ordered": false,
    "codes": [
      { "code": 1, "label": "More excited than concerned", "pole": "positive" },
      { "code": 2, "label": "More concerned than excited", "pole": "negative" },
      { "code": 3, "label": "Equally concerned and excited", "pole": "neutral" },
      { "code": 99, "label": "No answer", "missing": true, "missing_kind": "skipped" }
    ]
  }
}
```

The `concept_refs` entry is doing quiet work: it will let the 2021 wording variant share an identity with this question. More on that below.

The Wave 173 result:

```json
{
  "question_id": "cncexc",
  "dimension_id": "main",
  "base": { "kind": "all", "n_unweighted": 5023 },
  "distribution": {
    "kind": "categorical",
    "entries": [
      { "code": 1, "pct": 10 },
      { "code": 2, "pct": 50 },
      { "code": 3, "pct": 38 },
      { "code": 99, "pct": 1 }
    ]
  }
}
```

The Aug 2024, Jul-Aug 2023, and Dec 2022 waves each get a parallel result with the topline's percentages, `base.kind: "all"`, and no `n_unweighted`. Drop each into the corresponding wave's `results` array.

### The 2021 wording change

Pew's 2021 stem began with a definition of "artificial intelligence computer programs" and used that phrase throughout instead of "AI":

> Artificial intelligence computer programs are designed to learn tasks that humans typically do, for instance recognizing speech or pictures. Overall, would you say the increased use of artificial intelligence computer programs in daily life makes you feel…

Treating that as the same question as the current CNCEXC would erase the wording difference. Treating it as a separate question would sever the trend line. Iris's fix for minor wording drift is rename-and-bridge: a new question id, a shared `concept_refs` entry linking the two. Consumers grouping on `concept_refs` get the five-wave trend; consumers grouping on `question_id` get two clean time series.

Declare a sibling question, `cncexc_2021`, alongside `cncexc`, with the same response codes and the same `local:cncexc` concept_ref:

```json
{
  "id": "cncexc_2021",
  "stem": "",
  "concept_refs": [{ "scheme": "local", "id": "cncexc" }],
  "notes": "November 2021 wording variant of Pew's CNCEXC question. Bridged to cncexc via a shared concept_ref so consumers can derive a trend line across the wording change.",
  "dimensions": [
    {
      "id": "main",
      "text": "Artificial intelligence computer programs are designed to learn tasks that humans typically do, for instance recognizing speech or pictures. Overall, would you say the increased use of artificial intelligence computer programs in daily life makes you feel…"
    }
  ],
  "response_space": {
    "kind": "enum",
    "ordered": false,
    "codes": [
      { "code": 1, "label": "More excited than concerned", "pole": "positive" },
      { "code": 2, "label": "More concerned than excited", "pole": "negative" },
      { "code": 3, "label": "Equally concerned and excited", "pole": "neutral" },
      { "code": 99, "label": "No answer", "missing": true, "missing_kind": "skipped" }
    ]
  }
}
```

The 2021 wave (`waves[4]`) gets one result, against `cncexc_2021`:

```json
{
  "question_id": "cncexc_2021",
  "dimension_id": "main",
  "base": { "kind": "all" },
  "distribution": {
    "kind": "categorical",
    "entries": [
      { "code": 1, "pct": 18 },
      { "code": 2, "pct": 37 },
      { "code": 3, "pct": 45 },
      { "code": 99, "pct": 1 }
    ]
  }
}
```

All five waves now carry data. The remaining questions are asked only in Wave 173.

## AI_KNOWUSE: a 5-point importance scale

A standard Likert. Five substantive options plus "No answer". Ordered, with pole going from positive at "Extremely important" to negative at "Not at all important".

```json
{
  "id": "ai_knowuse",
  "stem": "",
  "notes": "Rotation: response options 1-5/5-1.",
  "dimensions": [
    {
      "id": "main",
      "text": "Looking ahead, how important do you think it is for people to understand what artificial intelligence (AI) is?"
    }
  ],
  "response_space": {
    "kind": "enum",
    "ordered": true,
    "codes": [
      { "code": 1, "label": "Extremely important", "value": 4, "pole": "positive" },
      { "code": 2, "label": "Very important", "value": 3, "pole": "positive" },
      { "code": 3, "label": "Somewhat important", "value": 2, "pole": "neutral" },
      { "code": 4, "label": "Not too important", "value": 1, "pole": "negative" },
      { "code": 5, "label": "Not at all important", "value": 0, "pole": "negative" },
      { "code": 99, "label": "No answer", "missing": true, "missing_kind": "skipped" }
    ]
  }
}
```

The result is one more entry in `waves[0].results`:

```json
{
  "question_id": "ai_knowuse",
  "dimension_id": "main",
  "base": { "kind": "all", "n_unweighted": 5023 },
  "distribution": {
    "kind": "categorical",
    "entries": [
      { "code": 1, "pct": 36 },
      { "code": 2, "pct": 37 },
      { "code": 3, "pct": 20 },
      { "code": 4, "pct": 3 },
      { "code": 5, "pct": 2 },
      { "code": 99, "pct": 1 }
    ]
  }
}
```

## AI2HAPPEN: a matrix

The first matrix. One shared stem asks how concerned the respondent is about each of two statements. Both statements use the same five-point concern scale plus "Not sure" and "No answer".

A matrix is one question with several dimensions sharing one response space. Each dimension (each row of the matrix) reports as its own result.

Two non-substantive options need different missing kinds here. "Not sure" is offered as an explicit option: `missing_kind: "dk"`. "No answer" catches skips and refusals that fall through the "Not sure" out: `missing_kind: "skipped"`.

```json
{
  "id": "ai2happen",
  "stem": "How concerned are you about each of the following for society?",
  "notes": "Items randomized; response options rotated 1-5/5-1 in the same order as AI_KNOWUSE, holding option 6 (Not sure) last.",
  "dimensions": [
    {
      "id": "miss_opp",
      "text": "People will miss opportunities to improve their lives by being too reluctant to use artificial intelligence (AI)"
    },
    {
      "id": "ability_worsens",
      "text": "People's ability to do things on their own will get worse because of using artificial intelligence (AI)"
    }
  ],
  "response_space": {
    "kind": "enum",
    "ordered": true,
    "codes": [
      { "code": 1, "label": "Extremely concerned", "value": 4 },
      { "code": 2, "label": "Very concerned", "value": 3 },
      { "code": 3, "label": "Somewhat concerned", "value": 2 },
      { "code": 4, "label": "Not too concerned", "value": 1 },
      { "code": 5, "label": "Not at all concerned", "value": 0 },
      { "code": 6, "label": "Not sure", "missing": true, "missing_kind": "dk" },
      { "code": 99, "label": "No answer", "missing": true, "missing_kind": "skipped" }
    ]
  }
}
```

Two results, one per row:

```json
{
  "question_id": "ai2happen",
  "dimension_id": "miss_opp",
  "base": { "kind": "all", "n_unweighted": 5023 },
  "distribution": {
    "kind": "categorical",
    "entries": [
      { "code": 1, "pct": 8 }, { "code": 2, "pct": 13 }, { "code": 3, "pct": 29 },
      { "code": 4, "pct": 28 }, { "code": 5, "pct": 11 }, { "code": 6, "pct": 10 },
      { "code": 99, "pct": 1 }
    ]
  }
},
{
  "question_id": "ai2happen",
  "dimension_id": "ability_worsens",
  "base": { "kind": "all", "n_unweighted": 5023 },
  "distribution": {
    "kind": "categorical",
    "entries": [
      { "code": 1, "pct": 24 }, { "code": 2, "pct": 27 }, { "code": 3, "pct": 31 },
      { "code": 4, "pct": 8 }, { "code": 5, "pct": 3 }, { "code": 6, "pct": 7 },
      { "code": 99, "pct": 1 }
    ]
  }
}
```

## AI_BENE and AI_RISK: paired rating scales

Both ask the respondent to rate AI from "Very high" to "Very low", with "Not sure" and "No answer" at the end. Same shape, opposite polarity: AI_BENE treats "Very high" as positive (lots of benefits is good), AI_RISK treats "Very high" as negative (lots of risks is bad). Pole is a display hint for consumers; the underlying codes are identical integers.

`ai_bene`:

```json
{
  "id": "ai_bene",
  "stem": "",
  "notes": "Rotation: response options 1-5/5-1 in the same order as AI_RISK, holding option 6 (Not sure) last.",
  "dimensions": [
    {
      "id": "main",
      "text": "How would you rate the benefits of artificial intelligence (AI) for society as a whole?"
    }
  ],
  "response_space": {
    "kind": "enum",
    "ordered": true,
    "codes": [
      { "code": 1, "label": "Very high", "value": 4, "pole": "positive" },
      { "code": 2, "label": "High", "value": 3, "pole": "positive" },
      { "code": 3, "label": "Medium", "value": 2, "pole": "neutral" },
      { "code": 4, "label": "Low", "value": 1, "pole": "negative" },
      { "code": 5, "label": "Very low", "value": 0, "pole": "negative" },
      { "code": 6, "label": "Not sure", "missing": true, "missing_kind": "dk" },
      { "code": 99, "label": "No answer", "missing": true, "missing_kind": "skipped" }
    ]
  }
}
```

`ai_risk` is the same structure with poles flipped and text adjusted. Both produce a straightforward categorical result:

```json
{
  "question_id": "ai_bene",
  "dimension_id": "main",
  "base": { "kind": "all", "n_unweighted": 5023 },
  "distribution": {
    "kind": "categorical",
    "entries": [
      { "code": 1, "pct": 6 }, { "code": 2, "pct": 19 }, { "code": 3, "pct": 41 },
      { "code": 4, "pct": 12 }, { "code": 5, "pct": 7 }, { "code": 6, "pct": 15 },
      { "code": 99, "pct": 1 }
    ]
  }
}
```

Picking integer codes 1-5 for this scale is load-bearing: the open-ended probes below filter on "AI_BENE=1,2" and "AI_RISK=4,5". Those integers need to match.

## AI_BENE_OEHIGH: the first conditional open-ended probe

The topline now branches. This probe runs only on Form 1 respondents who rated benefits "Very high" or "High". The base is 687 of the 5,023. Pew's coders read each verbatim response and assigned one or more codes from a taxonomy with bold NET roll-ups.

This is the first question that exercises four features at once: the `subgroup_schema`, conditional subgroups, a `multi_select` distribution, and published NETs. We add them in that order.

**First**, declare the form variable in `subgroup_schema`. Form assignment is a randomization cell; every respondent got one or the other. In Iris it lives as a subgroup variable, the same shape as a demographic:

```json
"subgroup_schema": {
  "variables": [
    {
      "id": "x_form",
      "label": "Form assignment (split-sample randomization)",
      "values": [
        { "code": 1, "label": "Form 1" },
        { "code": 2, "label": "Form 2" }
      ]
    }
  ]
}
```

**Second**, declare the two form subgroups on the wave. We also need `form1` on its own, because the conditional OE cohort declares `form1` as its parent. Add both to `waves[0].subgroups`:

```json
{
  "id": "form1",
  "label": "Form 1 respondents",
  "filters": [{ "variable_id": "x_form", "values": [1] }],
  "n_unweighted": 2505
},
{
  "id": "form1_bene_high",
  "label": "Form 1 respondents who rated AI benefits High or Very high",
  "parent_subgroup_id": "form1",
  "n_unweighted": 687,
  "filters": {
    "all_of": [
      { "variable_id": "x_form", "values": [1] },
      { "question_id": "ai_bene", "dimension_id": "main", "values": [1, 2] }
    ]
  }
}
```

The cohort's filter is the intersection of two tests: a randomization variable and a prior question response. The nested `all_of` form combines them. The `variable_id` leg points at `x_form`; the `question_id` leg uses the question-based form of `SubgroupMatch` to filter on `ai_bene`'s response directly. No second codebook: the `ai_bene` codes we already declared are the integers that pick out the cohort.

**Third**, declare the question. Its response space is the post-coded taxonomy. The bold NET rows in the topline become named `nets` on the response space, each with an explicit `members` list pointing at the raw codes:

```json
{
  "id": "ai_bene_oehigh",
  "stem": "",
  "notes": "Post-coded open-ended probe. Coders may assign multiple codes per verbatim response, so category percentages can sum to more than 100 - hence distribution.kind=\"multi_select\". Net percentages report the share of respondents who gave at least one response in the net's member categories.",
  "skip_notes": "Asked only of Form 1 respondents whose AI_BENE answer was 1 (Very high) or 2 (High). [N=687]",
  "dimensions": [
    {
      "id": "main",
      "text": "What is the main reason you rate the benefits of artificial intelligence (AI) as [IF AI_BENE=1 INSERT: \"very\"] high for society?"
    }
  ],
  "response_space": {
    "kind": "enum",
    "ordered": false,
    "codes": [
      { "code": "make_humans_better", "label": "Make humans better at doing tasks" },
      { "code": "time_better_ways", "label": "Humans will spend their time in better ways" },
      { "code": "improve_health_science", "label": "Improvements to health, medicine and scientific research" },
      { "code": "learn_more", "label": "Learn more, increased access to information" },
      { "code": "tech_benefits", "label": "Specific technological benefits" },
      { "code": "creativity", "label": "Increased creativity" },
      { "code": "general_societal_benefits", "label": "General societal benefits, push society forward" },
      { "code": "general_positive", "label": "General positive statement about AI" },
      { "code": "general_economic", "label": "General economic benefits" },
      { "code": "fill_labor_jobs", "label": "Fill labor shortages, create jobs" },
      { "code": "accessibility", "label": "Benefits people in need/Increases accessibility" },
      { "code": "benefits_low", "label": "Benefits are low" },
      { "code": "both_benefits_risks", "label": "There are both benefits and risks" },
      { "code": "other", "label": "Other" },
      { "code": "unclear", "label": "Unclear" },
      { "code": "dk", "label": "Don't know", "missing": true, "missing_kind": "dk" },
      { "code": "no_answer", "label": "No answer", "missing": true, "missing_kind": "skipped" }
    ],
    "nets": [
      { "id": "efficient_net", "label": "Make people more efficient",
        "members": ["make_humans_better", "time_better_ways"] },
      { "id": "expand_abilities_net", "label": "Expand human and technological abilities",
        "members": ["improve_health_science", "learn_more", "tech_benefits", "creativity"] },
      { "id": "economic_net", "label": "Economic benefits/Fill labor",
        "members": ["general_economic", "fill_labor_jobs"] }
    ]
  }
}
```

Several codes sit outside any net ("General societal benefits", "Other", "Unclear", and so on). They appear in the distribution without belonging to a roll-up. That's fine. Nets are for the themes Pew chose to group.

**Fourth**, the result. The distribution is `multi_select`, not `categorical`: coders assigned multiple themes to a single verbatim answer, so percentages can sum above 100. The published NET percentages go into `stats.nets`: Pew's numbers, not a recomputation from members:

```json
{
  "question_id": "ai_bene_oehigh",
  "dimension_id": "main",
  "subgroup_id": "form1_bene_high",
  "base": { "kind": "all", "n_unweighted": 687 },
  "distribution": {
    "kind": "multi_select",
    "entries": [
      { "code": "make_humans_better", "pct": 36 },
      { "code": "time_better_ways", "pct": 9 },
      { "code": "improve_health_science", "pct": 13 },
      { "code": "learn_more", "pct": 9 },
      { "code": "tech_benefits", "pct": 1 },
      { "code": "creativity", "pct": 1 },
      { "code": "general_societal_benefits", "pct": 7 },
      { "code": "general_positive", "pct": 5 },
      { "code": "general_economic", "pct": 2 },
      { "code": "fill_labor_jobs", "pct": 1 },
      { "code": "accessibility", "pct": 3 },
      { "code": "benefits_low", "pct": 5 },
      { "code": "both_benefits_risks", "pct": 2 },
      { "code": "other", "pct": 2 },
      { "code": "unclear", "pct": 4 },
      { "code": "dk", "pct": 1 },
      { "code": "no_answer", "pct": 20 }
    ]
  },
  "stats": {
    "nets": [
      { "id": "efficient_net", "pct": 41 },
      { "id": "expand_abilities_net", "pct": 23 },
      { "id": "economic_net", "pct": 3 }
    ]
  }
}
```

The net pcts are the "any-of-members" share, not the arithmetic sum. A respondent whose verbatim mentioned both "make humans better" and "time better ways" counts once against `efficient_net`, not twice. So `efficient_net = 41` sits below `36 + 9 = 45`; the gap is the overlap.

## AI_BENE_OELOW: a second cohort, different taxonomy

Same shape, new taxonomy. Form 1, "AI_BENE=4,5". Base 421. The codes and nets reflect reasons to rate benefits low, not high.

Add the cohort to `subgroups`:

```json
{
  "id": "form1_bene_low",
  "label": "Form 1 respondents who rated AI benefits Low or Very low",
  "parent_subgroup_id": "form1",
  "n_unweighted": 421,
  "filters": {
    "all_of": [
      { "variable_id": "x_form", "values": [1] },
      { "question_id": "ai_bene", "dimension_id": "main", "values": [4, 5] }
    ]
  }
}
```

The question declares the low-reasons taxonomy and its nets (five of them: erosion, distrust, accuracy, control, safety). The shape is identical to `ai_bene_oehigh`: enum codes, named nets, a `multi_select` distribution, published NET pcts in `stats.nets`. See [instance.json](instance.json) for the full code list; the pattern is the same as above.

## AI_RISK_OEHIGH: a Form 2 cohort

Form 2 this time, "AI_RISK=1,2". Base 1,515. The taxonomy overlaps with AI_BENE_OELOW (both are about downsides), but Pew's code list is not identical, so each question carries its own response space.

The new pieces are `form2` (the form-2 subgroup) and `form2_risk_high` (the conditional cohort):

```json
{
  "id": "form2",
  "label": "Form 2 respondents",
  "filters": [{ "variable_id": "x_form", "values": [2] }],
  "n_unweighted": 2518
},
{
  "id": "form2_risk_high",
  "label": "Form 2 respondents who rated AI risks High or Very high",
  "parent_subgroup_id": "form2",
  "n_unweighted": 1515,
  "filters": {
    "all_of": [
      { "variable_id": "x_form", "values": [2] },
      { "question_id": "ai_risk", "dimension_id": "main", "values": [1, 2] }
    ]
  }
}
```

The question and result follow the `ai_bene_oehigh` pattern.

## AI_RISK_OELOW: declared, suppressed

Pew published no result for this one: the Form 2 cohort rating risks Low or Very Low was n=119 and got suppressed as too small to analyze. We still declare the question and its cohort subgroup, so the schema record is complete and the concept is discoverable. No result goes into `waves[0].results`.

The cohort subgroup looks like `form2_risk_high` with `values: [4, 5]`. The question itself has no coded response space (Pew never published the taxonomy), so a `text` response space marks the intent:

```json
{
  "id": "ai_risk_oelow",
  "stem": "",
  "notes": "Declared but not reported: Pew suppressed the distribution because the Form 2 cohort rating risks as Low or Very Low was too small to analyze. Retained here so the schema record is complete.",
  "skip_notes": "Asked only of Form 2 respondents whose AI_RISK answer was 4 (Low) or 5 (Very low). [N=119, suppressed]",
  "dimensions": [
    {
      "id": "main",
      "text": "What is the main reason you rate the risks of artificial intelligence (AI) as [IF AI_RISK=5 INSERT: \"very\"] low for society?"
    }
  ],
  "response_space": { "kind": "text" }
}
```

A consumer still sees the question in the catalog and finds the cohort subgroup. The absence of a result matches the absence in the PDF.

## AI_ROLE: a 10-row matrix split across forms

Ten items total, but Form 1 saw items a-e and Form 2 saw items f-j. Same stem, same three-point role scale. This is what variants are for.

Declare the question with all ten dimensions at the question level, and add two variants that override the dimension set. Each variant inherits the stem and response space; only the items change.

```json
{
  "id": "ai_role",
  "stem": "How much of a role do you think artificial intelligence (AI) should play in each of the following areas…",
  "notes": "Items randomized. Form 1 respondents saw items a-e; Form 2 respondents saw items f-j.",
  "dimensions": [
    { "id": "govern", "text": "Making decisions about how to govern the country" },
    { "id": "love", "text": "Judging whether two people could fall in love" },
    { "id": "weather", "text": "Forecasting the weather" },
    { "id": "gov_fraud", "text": "Searching for fraud in government benefits claims" },
    { "id": "new_medicines", "text": "Developing new medicines" },
    { "id": "jury", "text": "Selecting who should serve on a jury" },
    { "id": "faith", "text": "Advising people about their faith in God" },
    { "id": "suspects", "text": "Identifying suspects in a crime" },
    { "id": "mental_health", "text": "Providing mental health support to people" },
    { "id": "financial_crimes", "text": "Searching for financial crimes" }
  ],
  "response_space": {
    "kind": "enum",
    "ordered": true,
    "codes": [
      { "code": 1, "label": "AI should play a big role", "value": 2, "pole": "positive" },
      { "code": 2, "label": "AI should play a small role", "value": 1, "pole": "neutral" },
      { "code": 3, "label": "AI should play no role at all", "value": 0, "pole": "negative" },
      { "code": 4, "label": "Not sure", "missing": true, "missing_kind": "dk" },
      { "code": 99, "label": "No answer", "missing": true, "missing_kind": "skipped" }
    ]
  },
  "variants": [
    {
      "variant_id": "form1",
      "label": "Form 1 (items a-e)",
      "dimensions_override": [
        { "id": "govern", "text": "Making decisions about how to govern the country" },
        { "id": "love", "text": "Judging whether two people could fall in love" },
        { "id": "weather", "text": "Forecasting the weather" },
        { "id": "gov_fraud", "text": "Searching for fraud in government benefits claims" },
        { "id": "new_medicines", "text": "Developing new medicines" }
      ]
    },
    {
      "variant_id": "form2",
      "label": "Form 2 (items f-j)",
      "dimensions_override": [
        { "id": "jury", "text": "Selecting who should serve on a jury" },
        { "id": "faith", "text": "Advising people about their faith in God" },
        { "id": "suspects", "text": "Identifying suspects in a crime" },
        { "id": "mental_health", "text": "Providing mental health support to people" },
        { "id": "financial_crimes", "text": "Searching for financial crimes" }
      ]
    }
  ]
}
```

Each item produces one result, with both `variant_id` and `subgroup_id` set. Pinning `subgroup_id` to `form1` or `form2` makes the base count (2,505 or 2,518) tie to a named filter rather than to "full sample" with an asterisk:

```json
{
  "question_id": "ai_role",
  "dimension_id": "govern",
  "variant_id": "form1",
  "subgroup_id": "form1",
  "base": { "kind": "all", "n_unweighted": 2505 },
  "distribution": {
    "kind": "categorical",
    "entries": [
      { "code": 1, "pct": 4 }, { "code": 2, "pct": 23 }, { "code": 3, "pct": 60 },
      { "code": 4, "pct": 13 }, { "code": 99, "pct": 1 }
    ]
  }
}
```

Repeat for all ten items, five under `form1` and five under `form2`.

## PAINTAI and SONGAI: parallel probes on different media

PAINTAI asks Form 1 about reacting to an AI-made painting; SONGAI asks Form 2 about an AI-made song. The answer options run parallel ("Like more / Like less / Not change your views"), but the stems differ in subject matter and each probe ran to only one form.

Iris handles this as two separate questions sharing a `local:ai_made_art_reaction` concept_ref. Treating them as variants of one question would be wrong: the stems are different questions about different media, not two wordings of the same question. The concept_ref lets a consumer group them when they want; the schema keeps them separate because that is what they are.

`paintai`:

```json
{
  "id": "paintai",
  "stem": "",
  "concept_refs": [{ "scheme": "local", "id": "ai_made_art_reaction" }],
  "notes": "Asked to Form 1 only. Paired with songai (Form 2) via the shared concept_ref. Response options rotated 1-2/2-1 with option 3 always held last.",
  "skip_notes": "Asked only of Form 1 respondents. [N=2,505]",
  "dimensions": [
    {
      "id": "main",
      "text": "Imagine you see a painting you really like. Later, you find out the painting was made by artificial intelligence (AI). Would finding out that the painting was made by AI make you…"
    }
  ],
  "response_space": {
    "kind": "enum",
    "ordered": false,
    "codes": [
      { "code": 1, "label": "Like the painting more", "pole": "positive" },
      { "code": 2, "label": "Like the painting less", "pole": "negative" },
      { "code": 3, "label": "Not change your views", "pole": "neutral" },
      { "code": 99, "label": "No answer", "missing": true, "missing_kind": "skipped" }
    ]
  }
}
```

`songai` has the same shape with "song" substituted for "painting" and Form 2 instead of Form 1.

Each result filters to its form via `subgroup_id`:

```json
{
  "question_id": "paintai",
  "dimension_id": "main",
  "subgroup_id": "form1",
  "base": { "kind": "all", "n_unweighted": 2505 },
  "distribution": {
    "kind": "categorical",
    "entries": [
      { "code": 1, "pct": 3 }, { "code": 2, "pct": 49 },
      { "code": 3, "pct": 48 }, { "code": 99, "pct": 1 }
    ]
  }
}
```

That finishes the catalog.

## Crosstabs

The topline gave us full marginals on the full sample. The report itself adds figures that slice those same marginals by demographics. Encoding a crosstab is the same shape as a topline result with two extras: a demographic variable in `subgroup_schema`, and a `subgroup_id` on each result that points at the cell.

### AI_HEARD by age band (Pg. 10)

The first crosstab in [results.md](results.md) reports the share of each age band that has heard "a lot" about AI:

| | 65+ | 50-64 | 30-49 | 18-29 |
|---|---:|---:|---:|---:|
| Have heard or read a lot about AI | 32 | 42 | 51 | 62 |

The second row of Pew's figure reports a USEAI item ("Interact with AI about once a day or more often"). USEAI is on the topline's omitted list, so we have not declared it as a question; that row is therefore not encoded. The AI_HEARD row is on a question we already have, so it slots straight in.

Three things to set up: an `age_band` variable in `subgroup_schema`, four age subgroups on Wave 173, and four results (one per age cell) against the existing `ai_heard` question.

**First**, declare the demographic. `age_band` joins `x_form` in the study-level `subgroup_schema`. Codes use snake_case so they survive round-tripping through tooling that dislikes hyphens or `+`:

```json
{
  "id": "age_band",
  "label": "Age band",
  "values": [
    { "code": "18_29", "label": "18-29" },
    { "code": "30_49", "label": "30-49" },
    { "code": "50_64", "label": "50-64" },
    { "code": "65_plus", "label": "65+" }
  ]
}
```

**Second**, declare the four age subgroups on `waves[0].subgroups`. Each is a flat one-leg filter on `age_band`. Pew did not publish per-cell unweighted Ns for this figure, so `n_unweighted` is omitted; the schema lets it drop:

```json
{
  "id": "age_18_29",
  "label": "Adults 18-29",
  "filters": [
    { "variable_id": "age_band", "values": ["18_29"] }
  ]
}
```

The other three (`age_30_49`, `age_50_64`, `age_65_plus`) follow the same shape.

**Third**, add the per-cell results. The Pg. 10 figure shows only the "A lot" share, but the next figure (Pg. 12, encoded below) reports the full A-lot/A-little/Nothing distribution for the same four age cells, with the "A lot" numbers matching exactly. Rather than carry two competing results per cell, we record one result per cell with the more complete Pg. 12 distribution. The Pg. 10 narrative is satisfied by a consumer projecting `entries[0].pct` ("A lot") across the four age results.

So this section sets up the variable and the subgroups; the result entries themselves are written below as part of Pg. 12.

### AI_HEARD by gender, age, race, education, and party (Pg. 12)

Pew's Pg. 12 figure adds full distributions for AI_HEARD across five demographic axes:

| | A lot | A little | Nothing at all |
|---|---:|---:|---:|
| U.S. Adults | 47 | 48 | 5 |
| Men | 53 | 44 | 3 |
| Women | 41 | 52 | 6 |
| 18-29 … 65+ | (as above) | … | … |
| White / Black / Hispanic / Asian | … | … | … |
| Postgrad … HS or less | … | … | … |
| Rep/Lean Rep / Dem/Lean Dem | … | … | … |

The U.S. Adults row matches the topline result and is not re-encoded. Each remaining row becomes one `ai_heard` result against a subgroup.

**First**, declare the four new demographic variables (`gender`, `race_ethnicity`, `education`, `party_id_with_leaners`) alongside `x_form` and `age_band` in `subgroup_schema`. All four are flat enums; we adopt Pew's already-rolled-up categories rather than reconstructing finer-grained source codes we don't have. The party variable is a worked example: Pew published `Rep/Lean Rep` and `Dem/Lean Dem` cells, which are leaner-allocated rollups of strong/weak/lean codes we never see. Declaring `party_id_with_leaners` with two values (`rep_lean_rep`, `dem_lean_dem`) keeps the filter-side simple; the README's nested `any_of` form would be needed only if we held the underlying party + lean variables and wanted to reconstruct the rollup ourselves.

```json
{
  "id": "race_ethnicity",
  "label": "Race and ethnicity (Pew convention: White, Black, Asian = single-race, non-Hispanic; Hispanic = any race)",
  "values": [
    { "code": "white_nh", "label": "White" },
    { "code": "black_nh", "label": "Black" },
    { "code": "hispanic", "label": "Hispanic" },
    { "code": "asian_nh", "label": "Asian (English-speakers only)" }
  ]
}
```

The race variable's `label` carries Pew's standard race-coding convention (single-race non-Hispanic for White/Black/Asian, any-race for Hispanic), so a downstream consumer can read the convention without chasing the original PDF footnote. The Asian-English-only caveat lives on the value's display label and on each result's `base.notes`. (Subgroups themselves carry no `notes` field in the schema, so caveats ride on the variable, the value label, or the result's base notes.)

**Second**, declare one subgroup per cell on `waves[0].subgroups`:

```json
{
  "id": "gender_men",
  "label": "Men",
  "filters": [
    { "variable_id": "gender", "values": ["men"] }
  ]
}
```

Eleven new subgroups in total: 2 gender + 4 race + 4 education + 2 party. (The 4 age subgroups were declared in the Pg. 10 section.)

**Third**, add one result per cell, each pinning `subgroup_id` to its cell. The figure's note ("Respondents who did not give an answer are not shown") tells us the denominator excludes the missing code, so `base.kind` is `"answered"` and the distribution lists only the three substantive codes. (Topline results, by contrast, used `base.kind: "all"` and included the `99` "No answer" entry. Same numbers, different denominator convention; the schema captures the difference per-result.)

```json
{
  "question_id": "ai_heard",
  "dimension_id": "main",
  "subgroup_id": "age_18_29",
  "base": {
    "kind": "answered",
    "notes": "Pew's Pg. 12 figure excludes 'No answer' from the denominator (\"Respondents who did not give an answer are not shown\"). The 'A lot' share matches the Pg. 10 age figure, which reported only that share against the same cell."
  },
  "distribution": {
    "kind": "categorical",
    "entries": [
      { "code": 1, "pct": 62 },
      { "code": 2, "pct": 35 },
      { "code": 3, "pct": 3 }
    ]
  }
}
```

The other fourteen results follow the same shape with the cell's percentages substituted. A consumer wanting "% who have heard a lot, by age" reads `entries[0].pct` across the four age results; one wanting the full topline distribution reads the no-`subgroup_id` result on the same question. Both are queries against the same `ai_heard` rows, distinguished by whether `subgroup_id` is set.

### AI_HEARD by age band, across waves (Pg. 13)

Pew's Pg. 13 chart pushes the 18-29 and 65+ "A lot" shares back through three earlier waves:

| | Dec '22 | Aug '23 | Aug '24 | Jun '25 |
|---|---:|---:|---:|---:|
| 18-29 | 33 | 39 | 54 | 62 |
| 65+ | 19 | 27 | 29 | 32 |

(The 30-49 and 50-64 cells in the chart are blank for prior waves; only the 2025 numbers appear, and those are already encoded under Pg. 12.)

This crosstab adds nothing to the question catalog and nothing to the study-level `subgroup_schema`; both `ai_heard` and `age_band` are already declared. What it does add is **subgroups on the trend-reference waves**. Subgroups are wave-scoped: each wave that reports a cell must declare that cell on its own `subgroups` array. So we add `age_18_29` and `age_65_plus` to each of the three trend waves (`w150-ish_2024-08`, `trend_2023-07`, `trend_2022-12`), with the same flat `age_band` filter shape we used on Wave 173.

```json
{
  "wave_id": "trend_2022-12",
  "label": "December 2022 - trend reference",
  "field_dates": { "start": "2022-12-12", "end": "2022-12-18" },
  "subgroups": [
    {
      "id": "age_18_29",
      "label": "Adults 18-29",
      "filters": [
        { "variable_id": "age_band", "values": ["18_29"] }
      ]
    },
    {
      "id": "age_65_plus",
      "label": "Adults 65 and older",
      "filters": [
        { "variable_id": "age_band", "values": ["65_plus"] }
      ]
    }
  ],
  "results": [ … ]
}
```

A subgroup id only has to be unique within its wave, so reusing the ids `age_18_29` and `age_65_plus` across all four waves is fine and convenient: a consumer assembling the trend just groups results on `(question_id="ai_heard", subgroup_id="age_18_29")` and orders by `field_dates.start`.

Then add the per-cell results. The chart shows only the "A lot" share, so each result carries one entry with `code: 1`, with `base.kind: "answered"` matching the Pg. 12 convention (and the figure's "did not give an answer are not shown" note):

```json
{
  "question_id": "ai_heard",
  "dimension_id": "main",
  "subgroup_id": "age_18_29",
  "base": {
    "kind": "answered",
    "notes": "Pew's Pg. 13 trend chart reports only the 'A lot' share for this age cell."
  },
  "distribution": {
    "kind": "categorical",
    "entries": [
      { "code": 1, "pct": 33 }
    ]
  }
}
```

Six new results in total: 18-29 and 65+ × three trend waves. The 2025 column of the chart is already covered by the Pg. 12 results on Wave 173, so we don't duplicate it.

## Done

The full instance is at [instance.json](instance.json).
