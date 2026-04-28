# Iris

A JSON schema for publishing public opinion survey toplines and crosstabs in a form you can parse, query, and aggregate.

## Status

Draft, under active development. The schema lives in the `dev` channel and changes without warning.

## What we're building

Internally, we use Iris to aggregate, analyze, and publish survey data from across the pollster landscape: Pew, Gallup, NORC, YouGov, Ipsos, and others. Every pollster publishes in its own bespoke topline format, and  everything downstream (comparison, trend lines, meta-analysis) requires PDF scaping. Iris is a common format that can house our internally produced data and other externally published data for comparison.

Externally, the opportunity this may unlock is a 538 or Real Clear Politics for issue polling. Essentially, cross-pollster aggregation on the questions central to American politics: abortion, guns, immigration, AI, climate, healthcare, etc. The issue-polling universe is an order of magnitude more complex than the horserace one, but a robust approach to aggregation and comparison would make consensus and outlier results on public opinion more obvious and actionable. 

## Why not something else

Four families of standards touch the data structure and format issue. None quite fit the job:

- **Survey-instrument formats** (DDI Codebook, DDI Lifecycle, Qualtrics QSF) describe questions and how they were asked. DDI Lifecycle has NCubes and DDI-CDI (2025) extends the family to multidimensional data, but neither variant is tailored for the kind of topline-plus-crosstab we're concerned with. QSF is a proprietary Qualtrics export, not an open standard.
- **Statistical-aggregate formats** (SDMX, W3C RDF Data Cube) describe multidimensional tables of numbers. SDMX concept schemes and code lists can carry some of the semantics around a measure, but neither standard has a first-class place for question wording, response options, or the instrument context a topline depends on.
- **Survey interchange formats** (Triple-S) move questions and microdata between commercial market-research systems. This is the closest existing prior art: it models question text, response options, and variable types. But it is microdata-shaped, has no native topline or crosstab structure, and has not been adopted by U.S. news or academic public-opinion publishers.
- **Horserace aggregator conventions** (FiveThirtyEight, RealClearPolitics) are flat tables that fit ballots. They don't describe attitudinal batteries, matrices, or crosstabs. FiveThirtyEight's CSVs were the closest thing to a convention here. RealClearPolitics never published a format at all; its "data" is HTML tables that downstream tools scrape.

We hope Iris can fill the gap between these standards. It borrows concepts from DDI and SDMX, but targets what pollsters actually publish.

## Where to start

- **`iris.schema.json`** - the schema itself. JSON Schema draft 2020-12. Field descriptions are the authoritative reference.
- **`examples/pew-atp-w173/`** - a fully worked example. Pew's American Trends Panel Wave 173, "AI and its impact" (June 2025), encoded end to end. Source PDFs under `sources/`, a walkthrough in `guide.md`, and the full instance at `instance.json`.
- **`www/`** - released copies of the schema and the generated HTML reference. `www/dev/` for the current unstable draft; stable releases will get immutable copies under `www/x.y.z/`.

The worked examples and the schema field descriptions are the two best resources.

## On the name

From [Iris (mythology)](https://en.wikipedia.org/wiki/Iris_(mythology)):

> In ancient Greek religion and mythology, Iris is [...] the personification of the rainbow. She functions as a messenger and servant to the Olympians, particularly Hera.

From [Iris (anatomy)](https://en.wikipedia.org/wiki/Iris_(anatomy)):

> The iris is a thin, annular structure in the eye [...] that is responsible for controlling the diameter and size of the pupil, and thus the amount of light reaching the retina. In optical terms, the pupil is the eye's aperture, while the iris is the diaphragm.
