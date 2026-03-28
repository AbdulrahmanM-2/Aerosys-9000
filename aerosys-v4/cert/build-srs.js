const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  Header, Footer, AlignmentType, HeadingLevel, BorderStyle, WidthType,
  ShadingType, LevelFormat, PageBreak
} = require('docx');
const fs = require('fs');

const NAVY="003366",BLUE="1F5C99",LGRAY="F2F4F6",MGRAY="D9DDE2",WHITE="FFFFFF";
const RED="C0392B",AMBER="E67E22",GREEN="1A7A3E";

const bdr={style:BorderStyle.SINGLE,size:4,color:"CCCCCC"};
const borders={top:bdr,bottom:bdr,left:bdr,right:bdr};
const nB={style:BorderStyle.NONE,size:0,color:"FFFFFF"};
const nBorders={top:nB,bottom:nB,left:nB,right:nB};

function cell(text,w,opts={}){
  const{bold=false,color="222222",bg=WHITE,align=AlignmentType.LEFT,sz=20,italic=false,vspan}=opts;
  return new TableCell({borders,width:{size:w,type:WidthType.DXA},
    shading:{fill:bg,type:ShadingType.CLEAR},
    margins:{top:80,bottom:80,left:120,right:120},
    ...(vspan?{rowSpan:vspan}:{}),
    children:[new Paragraph({alignment:align,children:[new TextRun({text,bold,color,size:sz,font:"Arial",italics:italic})]})]
  });
}
function hCell(t,w){return cell(t,w,{bold:true,color:WHITE,bg:NAVY,sz:20})}
function h1(text){return new Paragraph({heading:HeadingLevel.HEADING_1,spacing:{before:360,after:120},
  border:{bottom:{style:BorderStyle.SINGLE,size:8,color:BLUE,space:4}},
  children:[new TextRun({text,bold:true,color:NAVY,size:32,font:"Arial"})]})}
function h2(text){return new Paragraph({heading:HeadingLevel.HEADING_2,spacing:{before:240,after:80},
  children:[new TextRun({text,bold:true,color:BLUE,size:26,font:"Arial"})]})}
function h3(text){return new Paragraph({heading:HeadingLevel.HEADING_3,spacing:{before:180,after:60},
  children:[new TextRun({text,bold:true,color:"444444",size:24,font:"Arial"})]})}
function p(text,opts={}){
  const{bold=false,color="222222",sz=22,italic=false,align=AlignmentType.LEFT,before=60,after=60}=opts;
  return new Paragraph({alignment:align,spacing:{before,after},
    children:[new TextRun({text,bold,color,size:sz,font:"Arial",italics:italic})]});}
function bl(text,level=0){return new Paragraph({numbering:{reference:"bullets",level},spacing:{before:40,after:40},
  children:[new TextRun({text,size:22,font:"Arial"})]})}
function sp(h=120){return new Paragraph({spacing:{before:0,after:h},children:[]})}
function pb(){return new Paragraph({children:[new PageBreak()]})}

// Requirement block
function req(id, dal, title, text, rationale, verifyMethod, traceFrom){
  const dalColor=dal==="B"?AMBER:dal==="C"?BLUE:dal==="D"?"444444":"888888";
  return new Table({
    width:{size:9360,type:WidthType.DXA},
    columnWidths:[1600,1600,1600,4560],
    rows:[
      new TableRow({children:[
        cell("Req ID",1600,{bold:true,color:WHITE,bg:NAVY,sz:20}),
        cell("DAL",1600,{bold:true,color:WHITE,bg:NAVY,sz:20}),
        cell("Verify By",1600,{bold:true,color:WHITE,bg:NAVY,sz:20}),
        cell("Traces From",4560,{bold:true,color:WHITE,bg:NAVY,sz:20}),
      ]}),
      new TableRow({children:[
        cell(id,1600,{bold:true,color:NAVY,sz:22}),
        cell(dal,1600,{bold:true,color:dalColor,align:AlignmentType.CENTER,sz:22}),
        cell(verifyMethod,1600,{color:"333333"}),
        cell(traceFrom,4560,{color:"333333",sz:20}),
      ]}),
      new TableRow({children:[
        new TableCell({borders,colSpan:4,width:{size:9360,type:WidthType.DXA},
          shading:{fill:LGRAY,type:ShadingType.CLEAR},
          margins:{top:80,bottom:80,left:120,right:120},
          children:[
            new Paragraph({spacing:{before:0,after:40},children:[new TextRun({text:`Title: ${title}`,bold:true,color:NAVY,size:22,font:"Arial"})]}),
            new Paragraph({spacing:{before:0,after:40},children:[new TextRun({text:`Requirement: ${text}`,color:"222222",size:22,font:"Arial"})]}),
            new Paragraph({spacing:{before:0,after:0},children:[new TextRun({text:`Rationale: ${rationale}`,color:"555555",size:20,font:"Arial",italics:true})]}),
          ]
        })
      ]})
    ]
  });
}

const doc = new Document({
  numbering:{config:[
    {reference:"bullets",levels:[
      {level:0,format:LevelFormat.BULLET,text:"\u2022",alignment:AlignmentType.LEFT,
        style:{paragraph:{indent:{left:720,hanging:360}}}},
      {level:1,format:LevelFormat.BULLET,text:"\u25E6",alignment:AlignmentType.LEFT,
        style:{paragraph:{indent:{left:1080,hanging:360}}}},
    ]},
    {reference:"numbers",levels:[
      {level:0,format:LevelFormat.DECIMAL,text:"%1.",alignment:AlignmentType.LEFT,
        style:{paragraph:{indent:{left:720,hanging:360}}}},
    ]},
  ]},
  styles:{
    default:{document:{run:{font:"Arial",size:22}}},
    paragraphStyles:[
      {id:"Heading1",name:"Heading 1",basedOn:"Normal",next:"Normal",quickFormat:true,
        run:{size:32,bold:true,font:"Arial",color:NAVY},
        paragraph:{spacing:{before:360,after:120},outlineLevel:0}},
      {id:"Heading2",name:"Heading 2",basedOn:"Normal",next:"Normal",quickFormat:true,
        run:{size:26,bold:true,font:"Arial",color:BLUE},
        paragraph:{spacing:{before:240,after:80},outlineLevel:1}},
      {id:"Heading3",name:"Heading 3",basedOn:"Normal",next:"Normal",quickFormat:true,
        run:{size:24,bold:true,font:"Arial",color:"444444"},
        paragraph:{spacing:{before:180,after:60},outlineLevel:2}},
    ]
  },
  sections:[{
    properties:{page:{size:{width:12240,height:15840},margin:{top:1080,right:1080,bottom:1080,left:1080}}},
    headers:{default:new Header({children:[
      new Table({width:{size:10080,type:WidthType.DXA},columnWidths:[5000,5080],
        rows:[new TableRow({children:[
          new TableCell({borders:nBorders,width:{size:5000,type:WidthType.DXA},children:[
            new Paragraph({children:[new TextRun({text:"AeroSys 9000 — Software Requirements Specification",bold:true,color:NAVY,size:18,font:"Arial"})]}),
          ]}),
          new TableCell({borders:nBorders,width:{size:5080,type:WidthType.DXA},children:[
            new Paragraph({alignment:AlignmentType.RIGHT,children:[
              new TextRun({text:"AEROSYS-SRS-001 Rev A  |  DO-178C DAL B/C",size:18,color:"666666",font:"Arial"}),
            ]}),
          ]}),
        ]})]
      }),
      new Paragraph({border:{bottom:{style:BorderStyle.SINGLE,size:6,color:BLUE,space:1}},children:[]}),
    ]})},
    footers:{default:new Footer({children:[
      new Paragraph({border:{top:{style:BorderStyle.SINGLE,size:4,color:MGRAY,space:1}},alignment:AlignmentType.CENTER,
        children:[new TextRun({text:"PROPRIETARY — AeroSys Avionics Systems Ltd.  |  AEROSYS-SRS-001  |  Not for distribution",size:16,color:"888888",font:"Arial"})]
      })
    ]})},
    children:[

      // COVER
      sp(720),
      new Paragraph({alignment:AlignmentType.CENTER,spacing:{before:0,after:80},
        children:[new TextRun({text:"AEROSYS AVIONICS SYSTEMS LTD.",bold:true,color:NAVY,size:40,font:"Arial"})]}),
      new Paragraph({alignment:AlignmentType.CENTER,spacing:{before:0,after:360},
        border:{bottom:{style:BorderStyle.SINGLE,size:12,color:BLUE,space:8}},
        children:[new TextRun({text:"AeroSys 9000 Integrated Avionics Platform",color:BLUE,size:26,font:"Arial"})]}),
      sp(240),
      new Paragraph({alignment:AlignmentType.CENTER,spacing:{before:0,after:120},
        children:[new TextRun({text:"SOFTWARE REQUIREMENTS SPECIFICATION",bold:true,color:NAVY,size:48,font:"Arial"})]}),
      new Paragraph({alignment:AlignmentType.CENTER,spacing:{before:0,after:480},
        children:[new TextRun({text:"(SRS) — High-Level Requirements",bold:true,color:BLUE,size:32,font:"Arial"})]}),
      sp(120),
      new Table({width:{size:6000,type:WidthType.DXA},columnWidths:[2200,3800],rows:[
        new TableRow({children:[cell("Document Number",2200,{bold:true,color:WHITE,bg:NAVY}),cell("AEROSYS-SRS-001",3800,{bold:true,color:NAVY,sz:22})]}),
        new TableRow({children:[cell("Revision",2200,{bold:true,color:WHITE,bg:NAVY}),cell("A — Initial Baseline",3800)]}),
        new TableRow({children:[cell("Date",2200,{bold:true,color:WHITE,bg:NAVY}),cell("2026-03-14",3800)]}),
        new TableRow({children:[cell("PSAC Reference",2200,{bold:true,color:WHITE,bg:NAVY}),cell("AEROSYS-PSAC-001 Rev A",3800)]}),
        new TableRow({children:[cell("Classification",2200,{bold:true,color:WHITE,bg:NAVY}),cell("PROPRIETARY — RESTRICTED",3800,{bold:true,color:RED})]}),
      ]}),
      pb(),

      // 1. INTRODUCTION
      h1("1  Introduction"),
      h2("1.1  Purpose"),
      p("This Software Requirements Specification (SRS) defines the High-Level Requirements (HLRs) for the AeroSys 9000 Integrated Avionics Software Platform. These requirements are derived from the system-level requirements and the safety assessment documented in the PSAC (AEROSYS-PSAC-001)."),
      p("Each requirement is assigned a DO-178C Design Assurance Level (DAL) consistent with the safety assessment. All requirements are uniquely identified, traceable, verifiable, and unambiguous."),
      h2("1.2  Scope"),
      p("This SRS covers all software components listed in AEROSYS-PSAC-001 Section 2.1. Requirements are organised by functional area. Low-Level Requirements (LLRs) derived from these HLRs are documented in the Software Design Description (AEROSYS-SDD-001)."),
      h2("1.3  Requirement Identifier Convention"),
      p("Each requirement uses the identifier format:  AEROSYS-HLR-[AREA]-[NNN]"),
      bl("AREA codes: BUS (ARINC bus), FADEC, IRS, ADC, FMS, AFCS, CAS, DISP (display), API, ACM (aircraft config management)"),
      bl("NNN: three-digit sequence number within the area"),
      bl("Example: AEROSYS-HLR-FADEC-001"),
      h2("1.4  Verification Method Abbreviations"),
      new Table({width:{size:9360,type:WidthType.DXA},columnWidths:[1400,7960],rows:[
        new TableRow({children:[hCell("Code",1400),hCell("Verification Method",7960)]}),
        ...[["T","Test — execute the software and observe the output against expected results"],
            ["A","Analysis — mathematical or logical analysis of code, design, or data"],
            ["I","Inspection — review of source code or design document without execution"],
            ["R","Review — structured review of requirements, design, or test results"],
        ].map(([c,d])=>new TableRow({children:[cell(c,1400,{bold:true,color:NAVY,align:AlignmentType.CENTER}),cell(d,7960)]}))
      ]}),
      sp(),

      // 2. ARINC 429 BUS REQUIREMENTS
      pb(),
      h1("2  ARINC 429 Bus Interface Requirements"),
      h2("2.1  Word Format and Encoding"),
      p("These requirements apply to the AeroSys.ARINC429 package."),
      sp(80),
      req("AEROSYS-HLR-BUS-001","C","32-Bit Word Structure",
        "The software shall process ARINC 429 words as 32-bit unsigned integers with the bit field layout: bits 1–8 Label (LSB first on wire), bits 9–10 SDI, bits 11–29 Data, bits 30–31 SSM, bit 32 Parity, as defined in ARINC 429 Part 1 Revision 17 Section 2.",
        "ARINC 429 Part 1 specifies the exact bit layout. Incorrect field extraction would cause incorrect data values to be displayed.",
        "T, I","SYS-REQ-ARINC-001"),
      sp(80),
      req("AEROSYS-HLR-BUS-002","C","Odd Parity Validation",
        "The software shall validate the odd parity bit (bit 32) of every received ARINC 429 word. Words with invalid parity shall be rejected and shall not be used to update any displayed parameter. A parity error counter shall be maintained per bus channel.",
        "Parity errors indicate transmission corruption. Accepting corrupted words could cause incorrect flight parameter display.",
        "T","SYS-REQ-ARINC-002"),
      sp(80),
      req("AEROSYS-HLR-BUS-003","C","Label Bit Reversal",
        "The software shall reverse the bit order of the 8-bit label field when encoding and decoding ARINC 429 words, as ARINC 429 transmits labels with bit 1 (MSB of the octal label) on the wire first, resulting in the stored label byte being the bit-reversed representation.",
        "Failure to reverse the label bits would cause all label lookups to fail, resulting in incorrect data routing.",
        "T, A","SYS-REQ-ARINC-003"),
      sp(80),
      req("AEROSYS-HLR-BUS-004","C","BNR Decoding",
        "The software shall decode Binary (BNR) format ARINC 429 data fields using two's complement representation over 19 bits (bits 11–29). The SSM field shall determine the sign: SSM = 11 (binary) indicates positive; SSM = 01 indicates negative. Words with SSM = 00 (Failure Warning) or SSM = 01 without sign context shall return a null value and shall not update displayed parameters.",
        "Incorrect BNR decoding would cause numeric values to be systematically wrong by up to 100% of range.",
        "T","SYS-REQ-ARINC-004"),
      sp(80),
      req("AEROSYS-HLR-BUS-005","C","BNR Resolution Scaling",
        "The software shall scale decoded BNR integer values by the label-specific resolution constant (LSB value in engineering units) before presenting to higher-level functions. Resolution constants shall be as defined in ARINC 429 Part 2 for each label assignment and shall be configurable per aircraft type profile.",
        "Incorrect scaling would cause displayed values to be off by the ratio between incorrect and correct resolution.",
        "T, A","SYS-REQ-ARINC-001"),
      sp(80),
      req("AEROSYS-HLR-BUS-006","C","BCD Decoding",
        "The software shall decode Binary-Coded Decimal (BCD) format ARINC 429 data fields by extracting 4-bit BCD digits from the data field and converting to a numeric value multiplied by the label-specific scale factor.",
        "BCD is used for frequencies (VHF, ILS) and squawk codes. Incorrect decoding would display wrong frequencies.",
        "T","SYS-REQ-ARINC-005"),
      sp(80),
      req("AEROSYS-HLR-BUS-007","C","DIS Word Processing",
        "The software shall process Discrete (DIS) format ARINC 429 words by treating the 19-bit data field as a bitmask of independent discrete status flags. Each discrete bit shall be mapped to a named system state per the aircraft type profile label map.",
        "Incorrect discrete processing would cause status flags (AP engaged, TCAS mode) to be wrong.",
        "T","SYS-REQ-ARINC-006"),
      sp(80),
      req("AEROSYS-HLR-BUS-008","C","SSM Status Propagation",
        "The software shall propagate the SSM (Sign/Status Matrix) value with each decoded parameter. Functions consuming ARINC parameters shall not use values where SSM indicates Failure Warning (00) or No Computed Data (01). The SSM status shall be available in the API response for each decoded value.",
        "Using NCD or FW data could cause incorrect display of computed flight parameters.",
        "T","SYS-REQ-ARINC-002"),
      sp(),

      // 3. FADEC REQUIREMENTS
      h1("3  FADEC Bus Interface Requirements"),
      p("These requirements apply to the FADEC bus handling in AeroSys.Bus. The FADEC bus is a dedicated high-speed (100 kbps) ARINC 429 receive-only bus from each engine's FADEC Electronic Engine Controller (EEC)."),
      sp(80),
      req("AEROSYS-HLR-FADEC-001","B","N1 Data Reception",
        "The software shall receive and decode the N1 fan speed percentage from ARINC 429 label 0o061 (Engine 1), 0o062 (Engine 2), 0o063 (Engine 3), 0o064 (Engine 4) on the respective FADEC bus channel. The decoded value shall be in the range 0.0–110.0 % N1. Values outside this range shall be rejected and flagged as invalid.",
        "N1 is the primary pilot cue for engine thrust. Incorrect N1 display could cause the crew to mismanage thrust.",
        "T","SYS-REQ-ENG-001"),
      sp(80),
      req("AEROSYS-HLR-FADEC-002","B","EGT Data Reception",
        "The software shall receive and decode the Exhaust Gas Temperature from ARINC 429 label 0o071 (Engine 1) and 0o072 (Engine 2). The decoded value shall be in the range -60 to 1200 degrees Celsius. The software shall compare the EGT value against the aircraft-type-specific EGT limit for the active thrust rating (TOGA, MCT, CRZ) from the Aircraft Profile and set an exceedance flag if the limit is exceeded.",
        "EGT exceedance causes engine damage. The software must correctly identify exceedance against the correct limit for the active thrust rating.",
        "T","SYS-REQ-ENG-002"),
      sp(80),
      req("AEROSYS-HLR-FADEC-003","B","Thrust Rating Identification",
        "The software shall receive and decode the active thrust rating from ARINC 429 label 0o057 (discrete) on the FADEC bus. The decoded rating shall be one of: TOGA, FLEX, MCT, CLB, CRZ, IDLE, REVERSE. An unrecognised rating shall be treated as UNKNOWN and flagged for display.",
        "The displayed thrust rating is used by the crew to verify FADEC mode. Incorrect display could mask an inadvertent mode change.",
        "T","SYS-REQ-ENG-003"),
      sp(80),
      req("AEROSYS-HLR-FADEC-004","B","FADEC Status Monitoring",
        "The software shall receive and process the FADEC status discrete word from label 0o270. If the FADEC reports a fault condition (channel failure, sensor failure, or inhibited mode), the software shall raise a CAUTION level alert (AEROSYS-HLR-CAS-002) and flag the affected engine parameters as degraded.",
        "A FADEC fault requires crew awareness. The software must not mask FADEC faults.",
        "T","SYS-REQ-ENG-004"),
      sp(80),
      req("AEROSYS-HLR-FADEC-005","B","Engine Data Freshness",
        "The software shall monitor the time since the last valid reception of each engine parameter. If no valid word is received within 500 ms, the parameter shall be flagged as STALE and the displayed value shall be annotated with a STALE indicator. If no valid word is received within 2000 ms, the parameter shall be flagged as LOST and an advisory alert shall be raised.",
        "Loss of FADEC bus data could indicate a bus failure. The crew must be informed rather than seeing frozen values.",
        "T, A","SYS-REQ-ENG-005"),
      sp(),

      // 4. IRS REQUIREMENTS
      pb(),
      h1("4  Inertial Reference System Requirements"),
      p("These requirements apply to the IRS bus handling in AeroSys.Bus (IRS_1, IRS_2, IRS_3 channels). The aircraft carries three independent IRS units providing redundant attitude, position, and acceleration data."),
      sp(80),
      req("AEROSYS-HLR-IRS-001","C","Attitude Data Reception",
        "The software shall receive and decode pitch attitude from ARINC 429 label 0o324 and roll attitude from label 0o325 on each of the three IRS buses. Pitch range shall be -90.0 to +90.0 degrees; roll range shall be -180.0 to +180.0 degrees. Resolution shall be 0.00137 degrees per LSB.",
        "Attitude data drives the primary flight display (PFD). Incorrect attitude display is a major safety hazard.",
        "T","SYS-REQ-IRS-001"),
      sp(80),
      req("AEROSYS-HLR-IRS-002","C","IRS Voting and Comparison",
        "Where three valid IRS sources are available, the software shall perform a comparison check: if any single IRS value deviates from the median of all three by more than 2.0 degrees (pitch/roll) or 0.1 degrees (heading), the deviating source shall be flagged as MISCOMPARE and an advisory alert shall be raised. The flagged source shall not contribute to the displayed primary value.",
        "Triple IRS redundancy enables detection of a faulty IRS. The voting logic protects against a single IRS failure driving the display.",
        "T, A","SYS-REQ-IRS-002"),
      sp(80),
      req("AEROSYS-HLR-IRS-003","C","Position Data Reception",
        "The software shall receive and decode latitude from label 0o100 and longitude from label 0o101. Resolution shall be 0.000021458 degrees per LSB (approximately 2.4 metres). Latitude range shall be -90.0 to +90.0 degrees; longitude range shall be -180.0 to +180.0 degrees.",
        "Accurate position is required for navigation display and route deviation monitoring.",
        "T","SYS-REQ-IRS-003"),
      sp(80),
      req("AEROSYS-HLR-IRS-004","C","IRS Alignment Status",
        "The software shall monitor the IRS alignment status discrete from label 0o360. If any IRS is in ATT (attitude only) mode rather than full NAV mode, the navigation display shall indicate ATT mode and position data from that IRS shall be marked as degraded.",
        "IRS in ATT mode provides attitude but unreliable position. The crew must be aware.",
        "T","SYS-REQ-IRS-004"),
      sp(),

      // 5. AUTOPILOT REQUIREMENTS
      h1("5  Autopilot Interface Requirements"),
      p("These requirements apply to the autopilot command interface in AeroSys.Server and AeroSys.Datastore."),
      sp(80),
      req("AEROSYS-HLR-AFCS-001","B","AP Engage Command Validation",
        "Before setting the Autopilot Engaged state to TRUE, the software shall validate that all of the following conditions are satisfied: (a) pitch attitude is within -10.0 to +20.0 degrees; (b) roll attitude is within -30.0 to +30.0 degrees; (c) airspeed is within V_S1G*1.3 to V_MO - 10 knots for the active aircraft type; (d) the source field is a recognised value (pilot, copilot, fms, ground). If any condition is not satisfied, the engage command shall be rejected with HTTP 409 and the reason shall be returned in the error response.",
        "Engaging the autopilot outside the safe engagement envelope could cause an upset or structural exceedance.",
        "T","SYS-REQ-AFCS-001"),
      sp(80),
      req("AEROSYS-HLR-AFCS-002","B","AP Target Range Validation",
        "The software shall validate all autopilot target values against the active aircraft type profile before accepting them: target_altitude_ft shall be in range 0 to Max_Altitude_Ft; target_mach shall be in range 0.00 to M_MO; target_heading_deg shall be in range 0 to 360; target_vs_fpm shall be in range -8000 to +8000. Out-of-range values shall be rejected with HTTP 400.",
        "Out-of-range targets could command the autopilot to exceed the aircraft's certified envelope.",
        "T","SYS-REQ-AFCS-002"),
      sp(80),
      req("AEROSYS-HLR-AFCS-003","B","AP Disconnect Annunciation",
        "When the autopilot engaged state transitions from TRUE to FALSE by any means (command, protection, failure), the software shall immediately raise a CAUTION alert (AEROSYS-HLR-CAS-002) with message AP DISCONNECT. This alert shall not be suppressed or debounced.",
        "An inadvertent AP disconnect is a recognised cause of loss of control. The crew must be immediately informed.",
        "T","SYS-REQ-AFCS-003"),
      sp(),

      // 6. CREW ALERTING REQUIREMENTS
      pb(),
      h1("6  Crew Alerting System (CAS) Requirements"),
      sp(80),
      req("AEROSYS-HLR-CAS-001","C","Alert Severity Classification",
        "The software shall classify all alerts into exactly one of three severity levels: WARNING (red) for conditions requiring immediate action, CAUTION (amber) for conditions requiring prompt action, or ADVISORY (cyan) for conditions requiring crew awareness. The classification shall be hard-coded in the software per the aircraft type profile — it shall not be modifiable at runtime without a software change.",
        "Incorrect alert classification could cause the crew to mismanage a serious condition or be distracted by a false warning.",
        "T, I","SYS-REQ-CAS-001"),
      sp(80),
      req("AEROSYS-HLR-CAS-002","C","Master Warning and Caution Flags",
        "The software shall maintain a Master Warning flag (TRUE when any unacknowledged WARNING is active) and a Master Caution flag (TRUE when any unacknowledged CAUTION is active). These flags shall be returned in every response from the GET /alerts endpoint. Acknowledging all warnings shall clear the Master Warning flag; acknowledging all cautions shall clear the Master Caution flag.",
        "Master warning/caution flags are the primary attention-getters for the crew. They must accurately reflect the alert state.",
        "T","SYS-REQ-CAS-002"),
      sp(80),
      req("AEROSYS-HLR-CAS-003","C","Alert Acknowledgement",
        "The POST /alerts/{id}/acknowledge endpoint shall mark the identified alert as acknowledged. Acknowledgement shall set the acknowledged field to TRUE and record the acknowledgement timestamp. An acknowledged alert shall remain visible in the alert list with its acknowledged status. Acknowledging a non-existent alert shall return HTTP 404; acknowledging an already-acknowledged alert shall return HTTP 409.",
        "Alert acknowledgement confirms crew awareness. The system must track acknowledgement state accurately.",
        "T","SYS-REQ-CAS-003"),
      sp(),

      // 7. AIRCRAFT PROFILE REQUIREMENTS
      h1("7  Aircraft Profile Management Requirements"),
      sp(80),
      req("AEROSYS-HLR-ACM-001","D","Multi-Type Profile Registry",
        "The software shall maintain a registry of aircraft type profiles supporting at minimum the following ICAO types: A318, A319, A320, A321, A20N, A21N, B737, B738, B739, B38M, B39M, A359, A35K, A388. Each profile shall define: engine type, N1/EGT/N2 operating limits per thrust rating, VMO, MMO, maximum altitude, and ARINC 429 label resolution constants.",
        "The correct engine limits must be applied for each aircraft type. Using wrong limits could cause missed exceedance alerts.",
        "T, I","SYS-REQ-ACM-001"),
      sp(80),
      req("AEROSYS-HLR-ACM-002","D","Runtime Type Switching",
        "The PUT /aircraft endpoint shall allow the active aircraft type to be changed at runtime. The switch shall take effect for all subsequent parameter validation and display within one processing cycle (defined as 100 ms). The switch shall be rejected if a flight is in progress (defined as altitude above 400 ft AGL AND groundspeed above 80 knots), unless the command includes a force_override flag and the request originates from a ground source.",
        "Aircraft type switching during flight with wrong profile could apply wrong limits.",
        "T","SYS-REQ-ACM-002"),
      sp(),

      // 8. DISPLAY REQUIREMENTS
      h1("8  Display and API Requirements"),
      sp(80),
      req("AEROSYS-HLR-DISP-001","C","Telemetry Data Freshness",
        "The GET /telemetry endpoint shall return data that is no more than 500 ms old at the time of response. The response shall include a timestamp field indicating when the data snapshot was taken. If the data bus has not been updated within 500 ms, the response shall include a data_stale flag set to TRUE.",
        "Stale telemetry data could mislead a crew or ground operator about current aircraft state.",
        "T","SYS-REQ-API-001"),
      sp(80),
      req("AEROSYS-HLR-DISP-002","C","SSE Stream Rate",
        "The GET /telemetry/stream server-sent events endpoint shall transmit events at the rate specified in the rate_hz query parameter. The permitted range is 1 to 50 Hz. If rate_hz is not specified, the default rate shall be 10 Hz. Rates outside the permitted range shall be rejected with HTTP 400. The actual transmission rate shall not deviate from the specified rate by more than 10%.",
        "Applications depending on a fixed telemetry rate for safety-relevant functions need a reliable stream.",
        "T, A","SYS-REQ-API-002"),
      sp(80),
      req("AEROSYS-HLR-API-001","D","JWT Authentication",
        "All API endpoints except GET /health shall require a valid JWT Bearer token in the Authorization header. Requests without a token, with an expired token, or with an invalid signature shall be rejected with HTTP 401. Requests with a valid token that lacks the required scope shall be rejected with HTTP 403. The JWT secret shall be stored as an environment variable and shall not appear in any source file.",
        "Unauthenticated access to command endpoints (AP engage, thrust rating) is a security risk.",
        "T","SYS-REQ-API-003"),
      sp(),

      // 9. TRACEABILITY MATRIX
      pb(),
      h1("9  Requirements Traceability Matrix"),
      p("The following table provides the complete traceability from System Requirements to High-Level Requirements. This matrix shall be maintained under CM and updated whenever requirements change."),
      sp(80),
      new Table({
        width:{size:9360,type:WidthType.DXA},
        columnWidths:[2600,2400,1200,1600,1560],
        rows:[
          new TableRow({children:[hCell("HLR ID",2600),hCell("Traces to System Req",2400),hCell("DAL",1200),hCell("Verify Method",1600),hCell("Status",1560)]}),
          ...[
            ["AEROSYS-HLR-BUS-001","SYS-REQ-ARINC-001","C","T, I","DRAFT"],
            ["AEROSYS-HLR-BUS-002","SYS-REQ-ARINC-002","C","T","DRAFT"],
            ["AEROSYS-HLR-BUS-003","SYS-REQ-ARINC-003","C","T, A","DRAFT"],
            ["AEROSYS-HLR-BUS-004","SYS-REQ-ARINC-004","C","T","DRAFT"],
            ["AEROSYS-HLR-BUS-005","SYS-REQ-ARINC-001","C","T, A","DRAFT"],
            ["AEROSYS-HLR-BUS-006","SYS-REQ-ARINC-005","C","T","DRAFT"],
            ["AEROSYS-HLR-BUS-007","SYS-REQ-ARINC-006","C","T","DRAFT"],
            ["AEROSYS-HLR-BUS-008","SYS-REQ-ARINC-002","C","T","DRAFT"],
            ["AEROSYS-HLR-FADEC-001","SYS-REQ-ENG-001","B","T","DRAFT"],
            ["AEROSYS-HLR-FADEC-002","SYS-REQ-ENG-002","B","T","DRAFT"],
            ["AEROSYS-HLR-FADEC-003","SYS-REQ-ENG-003","B","T","DRAFT"],
            ["AEROSYS-HLR-FADEC-004","SYS-REQ-ENG-004","B","T","DRAFT"],
            ["AEROSYS-HLR-FADEC-005","SYS-REQ-ENG-005","B","T, A","DRAFT"],
            ["AEROSYS-HLR-IRS-001","SYS-REQ-IRS-001","C","T","DRAFT"],
            ["AEROSYS-HLR-IRS-002","SYS-REQ-IRS-002","C","T, A","DRAFT"],
            ["AEROSYS-HLR-IRS-003","SYS-REQ-IRS-003","C","T","DRAFT"],
            ["AEROSYS-HLR-IRS-004","SYS-REQ-IRS-004","C","T","DRAFT"],
            ["AEROSYS-HLR-AFCS-001","SYS-REQ-AFCS-001","B","T","DRAFT"],
            ["AEROSYS-HLR-AFCS-002","SYS-REQ-AFCS-002","B","T","DRAFT"],
            ["AEROSYS-HLR-AFCS-003","SYS-REQ-AFCS-003","B","T","DRAFT"],
            ["AEROSYS-HLR-CAS-001","SYS-REQ-CAS-001","C","T, I","DRAFT"],
            ["AEROSYS-HLR-CAS-002","SYS-REQ-CAS-002","C","T","DRAFT"],
            ["AEROSYS-HLR-CAS-003","SYS-REQ-CAS-003","C","T","DRAFT"],
            ["AEROSYS-HLR-ACM-001","SYS-REQ-ACM-001","D","T, I","DRAFT"],
            ["AEROSYS-HLR-ACM-002","SYS-REQ-ACM-002","D","T","DRAFT"],
            ["AEROSYS-HLR-DISP-001","SYS-REQ-API-001","C","T","DRAFT"],
            ["AEROSYS-HLR-DISP-002","SYS-REQ-API-002","C","T, A","DRAFT"],
            ["AEROSYS-HLR-API-001","SYS-REQ-API-003","D","T","DRAFT"],
          ].map(([hlr,sys,dal,vm,st])=>new TableRow({children:[
            cell(hlr,2600,{bold:true,color:NAVY,sz:18}),
            cell(sys,2400,{sz:18}),
            cell(dal,1200,{bold:true,color:dal==="B"?AMBER:dal==="C"?BLUE:"444444",align:AlignmentType.CENTER}),
            cell(vm,1600),
            cell(st,1560,{color:st==="DRAFT"?AMBER:"222222",italic:st==="DRAFT"}),
          ]}))
        ]
      }),
      sp(),
      p("Note: All requirements are in DRAFT status pending DER review. Status will be updated to BASELINE upon DER concurrence.", {italic:true,color:"555555",sz:20}),
    ]
  }]
});

Packer.toBuffer(doc).then(buf=>{
  fs.writeFileSync('/mnt/user-data/outputs/AEROSYS-SRS-001-RevA.docx', buf);
  console.log('SRS written');
});
