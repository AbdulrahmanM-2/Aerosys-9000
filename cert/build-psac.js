const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  Header, Footer, AlignmentType, HeadingLevel, BorderStyle, WidthType,
  ShadingType, NumberFormat, LevelFormat, TabStopType,
  TabStopPosition, PageBreak
} = require('docx');
const fs = require('fs');

// ── Colours ──────────────────────────────────────────────────────
const NAVY   = "003366";
const BLUE   = "1F5C99";
const LGRAY  = "F2F4F6";
const MGRAY  = "D9DDE2";
const WHITE  = "FFFFFF";
const RED    = "C0392B";
const AMBER  = "E67E22";
const GREEN  = "1A7A3E";

// ── Helpers ───────────────────────────────────────────────────────
const border = { style: BorderStyle.SINGLE, size: 4, color: "CCCCCC" };
const borders = { top: border, bottom: border, left: border, right: border };
const noBorder = { style: BorderStyle.NONE, size: 0, color: "FFFFFF" };
const noBorders = { top: noBorder, bottom: noBorder, left: noBorder, right: noBorder };

function cell(text, w, opts={}) {
  const { bold=false, color=NAVY, bg=WHITE, align=AlignmentType.LEFT, sz=20, italic=false } = opts;
  return new TableCell({
    borders,
    width: { size: w, type: WidthType.DXA },
    shading: { fill: bg, type: ShadingType.CLEAR },
    margins: { top: 80, bottom: 80, left: 120, right: 120 },
    verticalAlign: 'center',
    children: [new Paragraph({
      alignment: align,
      children: [new TextRun({ text, bold, color, size: sz, font: "Arial", italics: italic })]
    })]
  });
}

function hCell(text, w) {
  return cell(text, w, { bold: true, color: WHITE, bg: NAVY, sz: 20 });
}

function heading1(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_1,
    spacing: { before: 360, after: 120 },
    border: { bottom: { style: BorderStyle.SINGLE, size: 8, color: BLUE, space: 4 } },
    children: [new TextRun({ text, bold: true, color: NAVY, size: 32, font: "Arial" })]
  });
}

function heading2(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_2,
    spacing: { before: 240, after: 80 },
    children: [new TextRun({ text, bold: true, color: BLUE, size: 26, font: "Arial" })]
  });
}

function heading3(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_3,
    spacing: { before: 180, after: 60 },
    children: [new TextRun({ text, bold: true, color: "444444", size: 24, font: "Arial" })]
  });
}

function para(text, opts={}) {
  const { bold=false, color="222222", sz=22, italic=false, align=AlignmentType.LEFT, before=60, after=60 } = opts;
  return new Paragraph({
    alignment: align,
    spacing: { before, after },
    children: [new TextRun({ text, bold, color, size: sz, font: "Arial", italics: italic })]
  });
}

function bullet(text, opts={}) {
  const { level=0, color="222222", sz=22, bold=false } = opts;
  return new Paragraph({
    numbering: { reference: "bullets", level },
    spacing: { before: 40, after: 40 },
    children: [new TextRun({ text, color, size: sz, font: "Arial", bold })]
  });
}

function numbered(text, opts={}) {
  const { level=0, color="222222", sz=22, bold=false } = opts;
  return new Paragraph({
    numbering: { reference: "numbers", level },
    spacing: { before: 40, after: 40 },
    children: [new TextRun({ text, color, size: sz, font: "Arial", bold })]
  });
}

function pageBreak() {
  return new Paragraph({ children: [new PageBreak()] });
}

function spacer(h=120) {
  return new Paragraph({ spacing: { before: 0, after: h }, children: [] });
}

function infoTable(rows) {
  return new Table({
    width: { size: 9360, type: WidthType.DXA },
    columnWidths: [2800, 6560],
    rows: rows.map(([k, v]) => new TableRow({ children: [
      cell(k, 2800, { bold: true, color: NAVY, bg: LGRAY, sz: 20 }),
      cell(v, 6560, { color: "222222", sz: 20 }),
    ]}))
  });
}

// ── Document ─────────────────────────────────────────────────────
const doc = new Document({
  numbering: {
    config: [
      { reference: "bullets", levels: [
        { level: 0, format: LevelFormat.BULLET, text: "\u2022", alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 720, hanging: 360 } } } },
        { level: 1, format: LevelFormat.BULLET, text: "\u25E6", alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 1080, hanging: 360 } } } },
      ]},
      { reference: "numbers", levels: [
        { level: 0, format: LevelFormat.DECIMAL, text: "%1.", alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 720, hanging: 360 } } } },
        { level: 1, format: LevelFormat.LOWER_LETTER, text: "(%2)", alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 1080, hanging: 360 } } } },
      ]},
    ]
  },
  styles: {
    default: { document: { run: { font: "Arial", size: 22 } } },
    paragraphStyles: [
      { id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 32, bold: true, font: "Arial", color: NAVY },
        paragraph: { spacing: { before: 360, after: 120 }, outlineLevel: 0 } },
      { id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 26, bold: true, font: "Arial", color: BLUE },
        paragraph: { spacing: { before: 240, after: 80 }, outlineLevel: 1 } },
      { id: "Heading3", name: "Heading 3", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 24, bold: true, font: "Arial", color: "444444" },
        paragraph: { spacing: { before: 180, after: 60 }, outlineLevel: 2 } },
    ]
  },
  sections: [{
    properties: {
      page: {
        size: { width: 12240, height: 15840 },
        margin: { top: 1080, right: 1080, bottom: 1080, left: 1080 }
      }
    },
    headers: {
      default: new Header({
        children: [
          new Table({
            width: { size: 9360+720, type: WidthType.DXA },
            columnWidths: [5000, 5080],
            rows: [new TableRow({ children: [
              new TableCell({ borders: noBorders, width: { size: 5000, type: WidthType.DXA }, children: [
                new Paragraph({ children: [new TextRun({ text: "AeroSys 9000 — Plan for Software Aspects of Certification", bold: true, color: NAVY, size: 18, font: "Arial" })] })
              ]}),
              new TableCell({ borders: noBorders, width: { size: 5080, type: WidthType.DXA }, children: [
                new Paragraph({ alignment: AlignmentType.RIGHT, children: [
                  new TextRun({ text: "AEROSYS-PSAC-001  Rev: A", size: 18, color: "666666", font: "Arial" }),
                ]})
              ]}),
            ]})]
          }),
          new Paragraph({
            border: { bottom: { style: BorderStyle.SINGLE, size: 6, color: BLUE, space: 1 } },
            children: []
          }),
        ]
      })
    },
    footers: {
      default: new Footer({
        children: [
          new Paragraph({
            border: { top: { style: BorderStyle.SINGLE, size: 4, color: MGRAY, space: 1 } },
            alignment: AlignmentType.CENTER,
            children: [new TextRun({ text: "PROPRIETARY AND CONFIDENTIAL — AeroSys Avionics Systems Ltd.  |  DO-178C Certification Document  |  NOT FOR DISTRIBUTION", size: 16, color: "888888", font: "Arial" })]
          })
        ]
      })
    },
    children: [

      // ═══════════ COVER PAGE ═══════════
      spacer(720),
      new Paragraph({
        alignment: AlignmentType.CENTER,
        spacing: { before: 0, after: 80 },
        children: [new TextRun({ text: "AEROSYS AVIONICS SYSTEMS LTD.", bold: true, color: NAVY, size: 40, font: "Arial" })]
      }),
      new Paragraph({ alignment: AlignmentType.CENTER, spacing: { before: 0, after: 360 },
        border: { bottom: { style: BorderStyle.SINGLE, size: 12, color: BLUE, space: 8 } },
        children: [new TextRun({ text: "Integrated Avionics Software Platform", color: BLUE, size: 26, font: "Arial" })]
      }),
      spacer(240),
      new Paragraph({ alignment: AlignmentType.CENTER, spacing: { before: 0, after: 120 },
        children: [new TextRun({ text: "PLAN FOR SOFTWARE ASPECTS OF CERTIFICATION", bold: true, color: NAVY, size: 48, font: "Arial" })]
      }),
      new Paragraph({ alignment: AlignmentType.CENTER, spacing: { before: 0, after: 480 },
        children: [new TextRun({ text: "(PSAC)", bold: true, color: BLUE, size: 36, font: "Arial" })]
      }),
      spacer(120),
      new Table({
        width: { size: 6000, type: WidthType.DXA },
        columnWidths: [2200, 3800],
        rows: [
          new TableRow({ children: [
            cell("Document Number",  2200, { bold:true, color:WHITE, bg:NAVY, sz:20 }),
            cell("AEROSYS-PSAC-001", 3800, { bold:true, color:NAVY, sz:22 }),
          ]}),
          new TableRow({ children: [
            cell("Revision",    2200, { bold:true, color:WHITE, bg:NAVY, sz:20 }),
            cell("A — Initial Release", 3800, { color:"222222", sz:20 }),
          ]}),
          new TableRow({ children: [
            cell("Date",        2200, { bold:true, color:WHITE, bg:NAVY, sz:20 }),
            cell("2026-03-14",  3800, { color:"222222", sz:20 }),
          ]}),
          new TableRow({ children: [
            cell("Classification", 2200, { bold:true, color:WHITE, bg:NAVY, sz:20 }),
            cell("PROPRIETARY — RESTRICTED", 3800, { bold:true, color:RED, sz:20 }),
          ]}),
          new TableRow({ children: [
            cell("DO-178C Level", 2200, { bold:true, color:WHITE, bg:NAVY, sz:20 }),
            cell("Level B (primary) / Level C/D (displays)", 3800, { color:"222222", sz:20 }),
          ]}),
          new TableRow({ children: [
            cell("Certification Authority", 2200, { bold:true, color:WHITE, bg:NAVY, sz:20 }),
            cell("FAA AIR-6 / EASA NAA", 3800, { color:"222222", sz:20 }),
          ]}),
          new TableRow({ children: [
            cell("Prepared By", 2200, { bold:true, color:WHITE, bg:NAVY, sz:20 }),
            cell("AeroSys Software Certification Team", 3800, { color:"222222", sz:20 }),
          ]}),
          new TableRow({ children: [
            cell("Approved By", 2200, { bold:true, color:WHITE, bg:NAVY, sz:20 }),
            cell("DER / ACO Representative (TBD)", 3800, { color:"666666", sz:20, italic:true }),
          ]}),
        ]
      }),
      spacer(480),
      new Paragraph({ alignment: AlignmentType.CENTER, spacing: { before: 0, after: 60 },
        children: [new TextRun({ text: "This document is submitted to the FAA Aircraft Certification Office and/or EASA National Aviation Authority", italic: true, color: "555555", size: 19, font: "Arial" })]
      }),
      new Paragraph({ alignment: AlignmentType.CENTER, children: [
        new TextRun({ text: "for review and approval prior to commencement of software development activities.", italic: true, color: "555555", size: 19, font: "Arial" })
      ]}),
      pageBreak(),

      // ═══════════ REVISION HISTORY ═══════════
      heading1("Revision History"),
      new Table({
        width: { size: 9360, type: WidthType.DXA },
        columnWidths: [900, 1600, 2000, 4860],
        rows: [
          new TableRow({ children: [hCell("Rev",900), hCell("Date",1600), hCell("Author",2000), hCell("Description",4860)] }),
          new TableRow({ children: [
            cell("A", 900),cell("2026-03-14",1600),cell("Cert Team",2000),cell("Initial PSAC release for DER/ACO review",4860),
          ]}),
          new TableRow({ children: [
            cell("—",900,{color:"AAAAAA"}),cell("TBD",1600,{color:"AAAAAA"}),cell("",2000),cell("Post-DER review updates",4860,{color:"AAAAAA",italic:true}),
          ]}),
        ]
      }),
      spacer(),

      // ═══════════ 1. PURPOSE AND SCOPE ═══════════
      pageBreak(),
      heading1("1  Purpose and Scope"),
      heading2("1.1  Purpose"),
      para("This Plan for Software Aspects of Certification (PSAC) describes the means by which AeroSys Avionics Systems Ltd. will demonstrate compliance with RTCA DO-178C, Software Considerations in Airborne Systems and Equipment Certification, for the AeroSys 9000 Integrated Avionics Software Platform."),
      para("This document is submitted to the certification authority as required by DO-178C Section 11.1 and serves as the primary agreement document establishing the software life cycle, software levels, standards, and development environment to be used throughout the project."),
      heading2("1.2  System Description"),
      para("AeroSys 9000 is an integrated avionics software platform providing the following functions:"),
      bullet("Flight envelope monitoring and parameter display (PFD, ND, ECAM/EICAS)"),
      bullet("ARINC 429 bus interface — receive and decode data from FADEC, ADC, IRS, FMS, AFCS, ILS/MMR, TCAS, and system buses"),
      bullet("REST API data distribution layer for ground station and maintenance access"),
      bullet("Multi-aircraft type profile management (A318/A319/A320/A321, B737 NG/MAX, A350, A380)"),
      bullet("Autopilot mode and target management interface"),
      bullet("Crew alerting system (CAS) — WARNING / CAUTION / ADVISORY"),
      bullet("Flight management interface — route display, performance data, FMS targeting"),
      spacer(80),
      heading2("1.3  Applicability"),
      para("This PSAC applies to all software identified in Section 4 of this document. It covers software hosted on the aircraft-side processing unit and the associated Vercel Edge serverless layer used for ground and maintenance access."),
      heading2("1.4  Related Documents"),
      new Table({
        width: { size: 9360, type: WidthType.DXA },
        columnWidths: [2800, 2400, 4160],
        rows: [
          new TableRow({ children: [hCell("Document",2800),hCell("Number",2400),hCell("Title",4160)] }),
          ...[
            ["RTCA","DO-178C","Software Considerations in Airborne Systems and Equipment Certification"],
            ["RTCA","DO-278A","Software Integrity Assurance Considerations for CNS/ATM Systems"],
            ["RTCA","DO-330","Software Tool Qualification Considerations"],
            ["RTCA","DO-332","Object-Oriented Technology and Related Techniques"],
            ["SAE","ARP-4754A","Development of Civil Aircraft and Systems"],
            ["SAE","ARP-4761","Guidelines and Methods for the Conduct of the Safety Assessment Process"],
            ["RTCA","DO-160G","Environmental Conditions and Test Procedures for Airborne Equipment"],
            ["ARINC","ARINC 429 Part 1 Rev 17","Mark 33 Digital Information Transfer System"],
            ["FAA","AC 20-115D","Airborne Software Development Assurance Using EUROCAE ED-12 / RTCA DO-178"],
            ["EASA","AMC 20-115D","Airborne Software Development Assurance Using EUROCAE ED-12C"],
            ["AeroSys","AEROSYS-SRS-001","Software Requirements Specification"],
            ["AeroSys","AEROSYS-SDP-001","Software Development Plan"],
            ["AeroSys","AEROSYS-SVP-001","Software Verification Plan"],
          ].map(([org,num,title]) => new TableRow({ children: [
            cell(org,2800,{bold:true,color:NAVY}),cell(num,2400),cell(title,4160),
          ]}))
        ]
      }),

      // ═══════════ 2. SOFTWARE OVERVIEW ═══════════
      pageBreak(),
      heading1("2  Software Overview"),
      heading2("2.1  Software Functions"),
      para("The AeroSys 9000 software is organised into the following functional partitions. Each partition is independently allocated to a software level based on the safety assessment described in Section 3."),
      new Table({
        width: { size: 9360, type: WidthType.DXA },
        columnWidths: [2400, 1000, 1600, 4360],
        rows: [
          new TableRow({ children: [hCell("Software Component",2400),hCell("DAL",1000),hCell("Ada Package",1600),hCell("Function",4360)] }),
          ...[
            ["FADEC Bus Interface",     "B","AeroSys.Bus (FADEC)","Receive and validate FADEC ARINC 429 words; forward N1, EGT, FF, oil data"],
            ["TCAS RA Interface",       "B","AeroSys.Bus (TCAS)","Process TCAS resolution advisory commands from ARINC 429 bus"],
            ["Autopilot Mode Manager",  "B","AeroSys.Server (AP)","Accept and validate autopilot engage/disengage, mode, and target commands"],
            ["ARINC 429 Decode Layer",  "C","AeroSys.ARINC429","Word decode, parity check, BNR/BCD/DIS format parsing for all buses"],
            ["IRS Data Interface",      "C","AeroSys.Bus (IRS)","Receive and process attitude, position, acceleration from IRS buses"],
            ["ADC Data Interface",      "C","AeroSys.Bus (ADC)","Receive and process speed, altitude, temperature from ADC buses"],
            ["FMS Interface",           "C","AeroSys.Bus (FMS)","Receive route, performance, and targeting data from FMS buses"],
            ["Crew Alerting System",    "C","AeroSys.Datastore","Manage WARNING/CAUTION/ADVISORY alert states and acknowledgement"],
            ["PFD/ND Display Logic",    "C","AeroSys.Server","Format and serve telemetry data for cockpit display rendering"],
            ["Aircraft Profile Mgr",   "D","AeroSys.Aircraft","Maintain engine limits, performance envelopes, bus configurations"],
            ["REST API Layer",          "D","AeroSys.Server","Serve JSON responses to authorised external REST clients"],
            ["Bus Monitor Display",     "E","api/_arinc429.js","Ground display of ARINC 429 bus words — no flight effect"],
            ["Vercel Serverless Layer", "E","api/*.js","Stateless serverless functions for ground/maintenance access"],
          ].map(([comp,dal,pkg,fn]) => new TableRow({ children: [
            cell(comp,2400,{bold:dal==="A"||dal==="B"}),
            cell(dal,1000,{bold:true,color:dal==="A"?RED:dal==="B"?AMBER:dal==="C"?BLUE:dal==="D"?"444444":"888888",align:AlignmentType.CENTER}),
            cell(pkg,1600,{color:"333333",sz:18}),
            cell(fn,4360),
          ]}))
        ]
      }),
      spacer(),
      heading2("2.2  Software Architecture"),
      para("The software is implemented in Ada 2022 (aircraft-side) and JavaScript (ground layer). The architecture provides strict partitioning between safety levels through Ada's Protected Object mechanism, fixed-size buffers, and no dynamic memory allocation in DAL B/C components."),
      para("Key architectural properties:"),
      bullet("All inter-task communication through Ada Protected Objects (AeroSys.Datastore) with priority-ceiling protocol"),
      bullet("No dynamic memory allocation (no heap use) in DAL A/B/C components"),
      bullet("No unbounded recursion — all call graphs statically bounded"),
      bullet("Fixed-size string buffers throughout (String(1..N) constraints)"),
      bullet("Constrained numeric subtypes enforce physical ranges at compile time"),
      bullet("All ARINC 429 decoding validates parity before accepting data"),
      heading2("2.3  Hardware Description"),
      para("The target hardware platform is defined in the Hardware Qualification Plan (AEROSYS-HQP-001, TBD). The software is developed and verified on the following representative configuration:"),
      bullet("Processor: x86-64 or ARM Cortex-R52 (certification target TBD with customer)"),
      bullet("RTOS: VxWorks 653 or INTEGRITY-178 tuMP (DO-178C compliant)"),
      bullet("ARINC 429 interface: Astronics AceXtreme or DDC BU-65590 series cards"),
      bullet("Memory: 512 MB RAM minimum; no virtual memory in safety partitions"),

      // ═══════════ 3. CERTIFICATION BASIS ═══════════
      pageBreak(),
      heading1("3  Certification Basis and Software Levels"),
      heading2("3.1  Certification Authority"),
      infoTable([
        ["Primary Authority","FAA — Aircraft Certification Office (ACO), Transport Aircraft Directorate"],
        ["European Validation","EASA — per Bilateral Aviation Safety Agreement (BASA)"],
        ["Applicable FAA AC","AC 20-115D (DO-178C compliance)"],
        ["Applicable EASA AMC","AMC 20-115D"],
        ["DER Engagement","FAA-designated DER to be assigned prior to Phase 2"],
        ["ACO Point of Contact","TBD — to be established at PSAC submission meeting"],
      ]),
      spacer(),
      heading2("3.2  Safety Assessment Summary"),
      para("The software level assignments in Section 2.1 are derived from the System Safety Assessment (SSA) conducted per ARP-4754A and ARP-4761. The Functional Hazard Assessment (FHA) identified the following top-level failure conditions driving DAL assignments:"),
      new Table({
        width: { size: 9360, type: WidthType.DXA },
        columnWidths: [2600, 1800, 1200, 1200, 2560],
        rows: [
          new TableRow({ children: [hCell("Failure Condition",2600),hCell("Effect",1800),hCell("Severity",1200),hCell("DAL",1200),hCell("Software Function",2560)] }),
          ...[
            ["Incorrect thrust command transmitted to FADEC","Uncommanded thrust change — possible loss of control","Catastrophic","B*","FADEC Bus Interface"],
            ["TCAS RA command not correctly processed","Failure to avoid collision","Catastrophic","B*","TCAS RA Interface"],
            ["Incorrect autopilot targets accepted","Hazardous exceedance — severe workload increase","Hazardous","B","Autopilot Mode Manager"],
            ["ARINC parity error not detected","Invalid data used for display decisions","Major","C","ARINC 429 Decode Layer"],
            ["Incorrect IRS data displayed","Pilot orientation error — major workload","Major","C","IRS Data Interface"],
            ["FMS route data corrupted","Incorrect navigation guidance displayed","Major","C","FMS Interface"],
            ["Alert state incorrectly managed","Alert suppressed — delayed crew response","Major","C","Crew Alerting System"],
            ["Aircraft profile limits incorrect","Erroneous display of exceedance margins","Minor","D","Aircraft Profile Mgr"],
            ["REST API unavailable","Loss of ground access — no flight effect","No Safety Effect","E","REST API Layer"],
          ].map(([fc,eff,sev,dal,fn]) => new TableRow({ children: [
            cell(fc,2600),cell(eff,1800),
            cell(sev,1200,{bold:true,color:sev==="Catastrophic"?RED:sev==="Hazardous"?AMBER:sev==="Major"?BLUE:"444444",align:AlignmentType.CENTER}),
            cell(dal,1200,{bold:true,color:dal==="B"||dal==="B*"?AMBER:dal==="C"?BLUE:dal==="D"?"444444":"888888",align:AlignmentType.CENTER}),
            cell(fn,2560),
          ]}))
        ]
      }),
      spacer(80),
      para("* Note: FADEC and TCAS functions receive data only from the ARINC 429 bus and do not issue commands directly to flight-critical actuators in this architecture. The DAL B assignment reflects the potential for incorrect display driving incorrect pilot action. If future versions issue direct FADEC commands, these functions will be elevated to DAL A."),
      heading2("3.3  Alternatives and Deviations"),
      para("No deviations from DO-178C are planned at this time. Any deviations identified during development will be documented as Issue Papers and submitted to the ACO/DER for approval prior to implementation."),

      // ═══════════ 4. LIFE CYCLE ═══════════
      pageBreak(),
      heading1("4  Software Life Cycle"),
      heading2("4.1  Life Cycle Overview"),
      para("The AeroSys 9000 software life cycle follows a sequential waterfall model with feedback loops, as permitted by DO-178C Section 2. The life cycle consists of the following phases:"),
      new Table({
        width: { size: 9360, type: WidthType.DXA },
        columnWidths: [400, 2000, 1400, 5560],
        rows: [
          new TableRow({ children: [hCell("#",400),hCell("Phase",2000),hCell("Duration (est.)",1400),hCell("Key Outputs",5560)] }),
          ...[
            ["1","System Requirements & Safety","6–12 mo","FHA, FMEA, FTA, SSA, system requirements, DAL assignments, PSAC approved"],
            ["2","Software High-Level Requirements","4–8 mo","SRS (HLRs), traceability to system requirements, HLR review records"],
            ["3","Software Design (LLRs)","4–8 mo","SDD (LLRs), architecture diagrams, interface specifications, data flow"],
            ["4","Coding","8–18 mo","Baselined Ada/JS source, coding standard compliance records, code reviews"],
            ["5","Unit & Integration Testing","12–24 mo","LLT procedures, LLT results, HIL test results, MC/DC coverage data"],
            ["6","System Verification","4–8 mo","HLT procedures, HLT results, integration test results, traceability complete"],
            ["7","Configuration Management","Ongoing","Baselines, CCB records, problem reports, SCI"],
            ["8","SAS & Certification Submission","4–8 mo","SAS, full artifact package, DER review, ACO approval"],
          ].map(([n,ph,dur,out]) => new TableRow({ children: [
            cell(n,400,{bold:true,color:NAVY,align:AlignmentType.CENTER}),
            cell(ph,2000,{bold:true}),cell(dur,1400),cell(out,5560),
          ]}))
        ]
      }),
      spacer(),
      heading2("4.2  Transition Criteria"),
      para("Each phase transition requires satisfaction of the following criteria before proceeding:"),
      bullet("All planned reviews for the phase are complete with no open Category 1 findings"),
      bullet("All required documents are baselined in the CM system"),
      bullet("Problem reports from the phase are dispositioned (closed or accepted with rationale)"),
      bullet("DER/ACO hold points (if any) have been cleared"),
      bullet("Independence requirements have been satisfied (reviewer ≠ original author)"),
      heading2("4.3  Feedback Loops"),
      para("The following feedback loops are explicitly planned and do not require a formal deviation:"),
      bullet("Requirements errors discovered during design: update SRS, re-review affected sections, re-trace to system requirements"),
      bullet("Design errors discovered during coding: update SDD, re-review affected sections"),
      bullet("Requirement gaps discovered during testing: raise PR, update SRS and SDD, re-test"),
      bullet("Coverage gaps discovered during analysis: add test cases, re-run coverage, update SVTR"),

      // ═══════════ 5. STANDARDS ═══════════
      pageBreak(),
      heading1("5  Software Development Standards"),
      heading2("5.1  Requirements Standards"),
      para("Software requirements shall be written to satisfy the following quality attributes per DO-178C Section 5.1.1:"),
      bullet("Unambiguous — each requirement has exactly one valid interpretation"),
      bullet("Completeness — all system requirements allocated to software have corresponding HLRs"),
      bullet("Verifiable — each requirement can be tested by inspection, analysis, or test"),
      bullet("Consistent — no conflicting requirements"),
      bullet("Traceable — each HLR traces to one or more system requirements; each LLR to one or more HLRs"),
      bullet("Achievable — implementation feasibility confirmed by design"),
      heading2("5.2  Design Standards"),
      para("The AeroSys architecture standards are:"),
      bullet("Partitioning: DAL levels shall not share memory or task contexts without explicit analysis"),
      bullet("No global mutable state visible across package boundaries — all access through Protected Object (AeroSys.Datastore)"),
      bullet("Stack bounds: maximum stack depth for each task shall be determined by static analysis and verified by test"),
      bullet("Timing: worst-case execution time (WCET) for all DAL B/C interrupt handlers shall be bounded"),
      heading2("5.3  Coding Standards"),
      para("DAL A and B components: SPARK 2014 subset with GNATprove formal verification"),
      para("DAL C components: Ada 2022 with the following restrictions:"),
      bullet("No dynamic memory allocation (no new/unchecked_deallocation)"),
      bullet("No recursive subprograms"),
      bullet("No uninitialized variables — all objects given explicit initial values"),
      bullet("All exception handlers shall be documented with rationale"),
      bullet("No use of System.Address arithmetic outside of hardware interface layer"),
      bullet("Maximum cyclomatic complexity per subprogram: 15"),
      bullet("Maximum subprogram length: 200 lines"),
      para("DAL D and E components (JavaScript/Vercel layer): ESLint with airborne-js ruleset; no dynamic eval."),
      heading2("5.4  Verification Standards"),
      para("Reviews shall use the checklists in SVP Appendix A. Each checklist item shall be marked Pass, Fail, or N/A with written justification for N/A."),
      para("Testing shall achieve the following structural coverage objectives:"),
      new Table({
        width: { size: 9360, type: WidthType.DXA },
        columnWidths: [1200, 2200, 2200, 2200, 1560],
        rows: [
          new TableRow({ children: [hCell("DAL",1200),hCell("Statement",2200),hCell("Decision/Branch",2200),hCell("MC/DC",2200),hCell("Notes",1560)] }),
          new TableRow({ children: [cell("A",1200,{bold:true,color:RED,align:AlignmentType.CENTER}),cell("Required",2200,{color:GREEN,bold:true}),cell("Required",2200,{color:GREEN,bold:true}),cell("Required",2200,{color:GREEN,bold:true}),cell("+ structural coverage of data coupling",1560)] }),
          new TableRow({ children: [cell("B",1200,{bold:true,color:AMBER,align:AlignmentType.CENTER}),cell("Required",2200,{color:GREEN,bold:true}),cell("Required",2200,{color:GREEN,bold:true}),cell("Required",2200,{color:GREEN,bold:true}),cell("GNATprove for SPARK components",1560)] }),
          new TableRow({ children: [cell("C",1200,{bold:true,color:BLUE,align:AlignmentType.CENTER}),cell("Required",2200,{color:GREEN,bold:true}),cell("Required",2200,{color:GREEN,bold:true}),cell("Not required",2200,{color:"666666"}),cell("",1560)] }),
          new TableRow({ children: [cell("D",1200,{bold:true,color:"444444",align:AlignmentType.CENTER}),cell("Required",2200,{color:GREEN,bold:true}),cell("Not required",2200,{color:"666666"}),cell("Not required",2200,{color:"666666"}),cell("",1560)] }),
          new TableRow({ children: [cell("E",1200,{bold:true,color:"888888",align:AlignmentType.CENTER}),cell("Not required",2200,{color:"666666"}),cell("Not required",2200,{color:"666666"}),cell("Not required",2200,{color:"666666"}),cell("",1560)] }),
        ]
      }),

      // ═══════════ 6. DEVELOPMENT ENVIRONMENT ═══════════
      pageBreak(),
      heading1("6  Software Development Environment"),
      heading2("6.1  Development Tools"),
      new Table({
        width: { size: 9360, type: WidthType.DXA },
        columnWidths: [2200, 1600, 1200, 4360],
        rows: [
          new TableRow({ children: [hCell("Tool",2200),hCell("Version",1600),hCell("TQL",1200),hCell("Usage / Qualification Basis",4360)] }),
          ...[
            ["GNAT Pro (AdaCore)","24.0","TQL-5","Ada 2022 compiler — qualification data provided by AdaCore Qualification Kit"],
            ["GNATprove","24.0","TQL-1","SPARK 2014 formal verification — produces proof obligations for DAL B"],
            ["GNATtest","24.0","TQL-5","Unit test skeleton generation — output reviewed and supplemented manually"],
            ["GNATcoverage","24.0","TQL-1","Source coverage analysis — MC/DC and statement/branch"],
            ["gprbuild","24.0","TQL-5","Build system — deterministic, reproducible builds"],
            ["GNATcheck","24.0","TQL-5","Coding standard enforcement — DO-178C Ada subset rules"],
            ["GNATstack","24.0","TQL-1","Static stack analysis — worst-case stack depth"],
            ["Node.js","20 LTS","TQL-5","JavaScript runtime for Vercel layer (DAL E only)"],
            ["Git","2.43","TQL-5","Configuration management — all baselines tagged"],
            ["DOORS / Polarion","TBD","TQL-5","Requirements management and traceability"],
            ["Jenkins","TBD","TQL-5","CI/CD pipeline — automated build and test execution"],
          ].map(([t,v,q,u]) => new TableRow({ children: [
            cell(t,2200,{bold:true}),cell(v,1600),
            cell(q,1200,{bold:true,color:q==="TQL-1"?GREEN:q==="TQL-5"?BLUE:"444444",align:AlignmentType.CENTER}),
            cell(u,4360),
          ]}))
        ]
      }),
      spacer(80),
      heading2("6.2  Tool Qualification"),
      para("Tools that could introduce undetected errors into the deliverable software (TQL-1 through TQL-4) require qualification per DO-330. GNATprove and GNATcoverage are TQL-1 tools. Their qualification is addressed in the Tool Qualification Plan (AEROSYS-TQP-001, TBD)."),
      para("TQL-5 tools (compilers, build tools, test harnesses) must have their correct installation verified and their outputs reviewed. The GNAT Pro Qualification Kit provided by AdaCore covers TQL-5 qualification for GNAT Pro, gprbuild, GNATtest, GNATcheck, and GNATstack."),
      heading2("6.3  Configuration Management"),
      para("All software life cycle data shall be managed under CM per the Software Configuration Management Plan (AEROSYS-SCMP-001). Key CM controls:"),
      bullet("All source files, requirements documents, design documents, test procedures, and test results shall be stored in Git with signed tags for each baseline"),
      bullet("Change Control Board (CCB) approval required for any change to a baselined artifact"),
      bullet("Problem reports shall be tracked in a dedicated PR system; no PR shall be closed without disposition"),
      bullet("Software Configuration Index (SCI) shall be maintained and submitted with the SAS"),

      // ═══════════ 7. SCHEDULE ═══════════
      pageBreak(),
      heading1("7  Schedule and Hold Points"),
      heading2("7.1  Certification Milestones"),
      new Table({
        width: { size: 9360, type: WidthType.DXA },
        columnWidths: [400, 3200, 2000, 3760],
        rows: [
          new TableRow({ children: [hCell("M",400),hCell("Milestone",3200),hCell("Target Date",2000),hCell("Deliverable / Criterion",3760)] }),
          ...[
            ["M1","PSAC submitted to ACO/DER","2026-04-01","This document; ACO/DER engagement established"],
            ["M2","PSAC approved by ACO/DER","2026-06-01","Written DER concurrence; development authorised"],
            ["M3","SRS baseline (HLRs complete)","2026-10-01","AEROSYS-SRS-001 Rev A baselined; HLR review complete"],
            ["M4","SDD baseline (LLRs complete)","2027-03-01","AEROSYS-SDD-001 Rev A baselined; design review complete"],
            ["M5","Code baseline","2027-12-01","All source baselined; code review complete; no Category 1 PRs open"],
            ["M6","LLT complete (unit tests)","2028-06-01","All LLTs passed; MC/DC coverage achieved for DAL B"],
            ["M7","HLT complete (system tests)","2028-12-01","All HLTs passed; traceability matrix 100% complete"],
            ["M8","SAS submitted","2029-03-01","AEROSYS-SAS-001; complete artifact package"],
            ["M9","Type Certificate / STC","2029-09-01","FAA/EASA approval — subject to authority schedule"],
          ].map(([n,ms,dt,del]) => new TableRow({ children: [
            cell(n,400,{bold:true,color:NAVY,align:AlignmentType.CENTER}),
            cell(ms,3200,{bold:true}),cell(dt,2000),cell(del,3760),
          ]}))
        ]
      }),
      spacer(),
      heading2("7.2  Hold Points"),
      para("The following hold points require DER/ACO review and written approval before proceeding:"),
      bullet("HP-1: PSAC approval — no software development shall commence until ACO/DER approval of this document"),
      bullet("HP-2: SRS approval — no detailed design shall commence until HLRs are approved"),
      bullet("HP-3: Coverage analysis review — DER review of MC/DC evidence before HLT commences"),
      bullet("HP-4: SAS review — DER review of complete artifact package before certification authority submission"),

      // ═══════════ 8. ADDITIONAL CONSIDERATIONS ═══════════
      pageBreak(),
      heading1("8  Additional Considerations"),
      heading2("8.1  Previously Developed Software (PDS)"),
      para("No previously developed software (PDS) is used in DAL A/B components. The AeroSys 9000 codebase is developed from scratch for this project."),
      para("The following pre-existing components are used in DAL C/D/E roles and require credit analysis:"),
      bullet("Ada runtime library (GNAT Pro RTS) — DAL C credit requires runtime qualification (AdaCore RTS qualification data available)"),
      bullet("Vercel serverless runtime (Node.js) — DAL E only; no credit required"),
      heading2("8.2  Commercial Off-The-Shelf (COTS) Software"),
      para("No COTS software with safety function is used. The ARINC 429 decoding library is developed in-house (AeroSys.ARINC429 package)."),
      heading2("8.3  Multi-Version Dissimilar Software"),
      para("Not applicable for the current architecture. If redundant dissimilar software channels are added in future, this section will be updated with the dissimilarity analysis per DO-178C Section 12.3.3."),
      heading2("8.4  User-Modifiable Software"),
      para("The aircraft type profile data (AeroSys.Aircraft package) contains modifiable parameters. These parameters are controlled through the CM system and require CCB approval for any change. Field modifications are not permitted."),
      heading2("8.5  Option-Selectable Software"),
      para("Software options (aircraft type selection) are controlled through protected configuration data managed per the CM plan. All option combinations are tested as part of the verification program."),
      heading2("8.6  Formal Methods"),
      para("SPARK 2014 formal verification (GNATprove) will be applied to all DAL B components. GNATprove is used to prove:"),
      bullet("Absence of runtime errors (ATC — absence of runtime checks)"),
      bullet("Correct data flow (information flow analysis)"),
      bullet("Subprogram contracts (Pre/Post conditions on all public subprograms)"),
      para("GNATprove qualification is addressed in the Tool Qualification Plan per DO-330."),

      // ═══════════ 9. AGREEMENT ═══════════
      pageBreak(),
      heading1("9  Compliance Statement and Approval"),
      para("The undersigned parties agree that this PSAC accurately describes the approach to be used for demonstrating DO-178C compliance for the AeroSys 9000 Integrated Avionics Software Platform and commit to executing the activities described herein."),
      spacer(240),
      new Table({
        width: { size: 9360, type: WidthType.DXA },
        columnWidths: [4680, 4680],
        rows: [
          new TableRow({ children: [
            cell("Prepared by — AeroSys Software Certification Team",4680,{bold:true,color:NAVY,bg:LGRAY}),
            cell("DER Review and Concurrence",4680,{bold:true,color:NAVY,bg:LGRAY}),
          ]}),
          new TableRow({ children: [
            new TableCell({ borders, width:{size:4680,type:WidthType.DXA}, margins:{top:80,bottom:80,left:120,right:120},
              children: [
                new Paragraph({spacing:{before:0,after:40},children:[new TextRun({text:"Name: ________________________________",color:"333333",size:22,font:"Arial"})]}),
                new Paragraph({spacing:{before:0,after:40},children:[new TextRun({text:"Title: ________________________________",color:"333333",size:22,font:"Arial"})]}),
                new Paragraph({spacing:{before:0,after:40},children:[new TextRun({text:"Signature: ____________________________",color:"333333",size:22,font:"Arial"})]}),
                new Paragraph({spacing:{before:0,after:0},children:[new TextRun({text:"Date: _________________________________",color:"333333",size:22,font:"Arial"})]}),
              ]
            }),
            new TableCell({ borders, width:{size:4680,type:WidthType.DXA}, margins:{top:80,bottom:80,left:120,right:120},
              children: [
                new Paragraph({spacing:{before:0,after:40},children:[new TextRun({text:"DER Name: _____________________________",color:"333333",size:22,font:"Arial"})]}),
                new Paragraph({spacing:{before:0,after:40},children:[new TextRun({text:"DER Certificate No.: ___________________",color:"333333",size:22,font:"Arial"})]}),
                new Paragraph({spacing:{before:0,after:40},children:[new TextRun({text:"Signature: ____________________________",color:"333333",size:22,font:"Arial"})]}),
                new Paragraph({spacing:{before:0,after:0},children:[new TextRun({text:"Date: _________________________________",color:"333333",size:22,font:"Arial"})]}),
              ]
            }),
          ]}),
          new TableRow({ children: [
            cell("ACO / NAA Point of Contact",4680,{bold:true,color:NAVY,bg:LGRAY}),
            cell("Quality Assurance Witness",4680,{bold:true,color:NAVY,bg:LGRAY}),
          ]}),
          new TableRow({ children: [
            new TableCell({ borders, width:{size:4680,type:WidthType.DXA}, margins:{top:80,bottom:80,left:120,right:120},
              children: [
                new Paragraph({spacing:{before:0,after:40},children:[new TextRun({text:"ACO Name: ____________________________",color:"333333",size:22,font:"Arial"})]}),
                new Paragraph({spacing:{before:0,after:40},children:[new TextRun({text:"Office: ________________________________",color:"333333",size:22,font:"Arial"})]}),
                new Paragraph({spacing:{before:0,after:40},children:[new TextRun({text:"Signature: ____________________________",color:"333333",size:22,font:"Arial"})]}),
                new Paragraph({spacing:{before:0,after:0},children:[new TextRun({text:"Date: _________________________________",color:"333333",size:22,font:"Arial"})]}),
              ]
            }),
            new TableCell({ borders, width:{size:4680,type:WidthType.DXA}, margins:{top:80,bottom:80,left:120,right:120},
              children: [
                new Paragraph({spacing:{before:0,after:40},children:[new TextRun({text:"QA Name: _____________________________",color:"333333",size:22,font:"Arial"})]}),
                new Paragraph({spacing:{before:0,after:40},children:[new TextRun({text:"Organisation: __________________________",color:"333333",size:22,font:"Arial"})]}),
                new Paragraph({spacing:{before:0,after:40},children:[new TextRun({text:"Signature: ____________________________",color:"333333",size:22,font:"Arial"})]}),
                new Paragraph({spacing:{before:0,after:0},children:[new TextRun({text:"Date: _________________________________",color:"333333",size:22,font:"Arial"})]}),
              ]
            }),
          ]}),
        ]
      }),
    ]
  }]
});

Packer.toBuffer(doc).then(buf => {
  fs.writeFileSync('/mnt/user-data/outputs/AEROSYS-PSAC-001-RevA.docx', buf);
  console.log('PSAC written');
});
