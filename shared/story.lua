M8Story = {}
M8Story.Title = 'MURDER OF 8'
M8Story.Subtitle = 'THE LAST WITNESS'

M8Story.Chapters = {
    [1] = {
        id = 'burning_house', number = '01', title = 'THE HOUSE THAT ONLY BURNS AT NIGHT',
        location = 'Burning House',
        intro = 'A house that refuses to stay dead. From 1:00 AM until 3:00 AM, the fire comes back.',
        requiredEvidence = { 'rusk_body', 'fire_report', 'bell' },
        completionText = 'THE FIRST ONE LIED WITH FIRE.\n\nTHE SECOND LIED TO GOD.',
        nextHint = 'Find the place where Sandy asks for forgiveness.',
        placeHint = 'Churchyard dirt on his boots. Whoever hung him had knelt somewhere first.',
        evidence = {
            rusk_body = {
                label = 'Examine Elias Rusk', shortTitle = 'ELIAS RUSK',
                hint = "A fire inspector does not die in a fire. He went down behind the house, by the table with the bottles. One boot is still there.",
                body = [[ELIAS RUSK

Former fire inspector.

His body hung from a ceiling beam. His boots stop several inches above the floor. His hands were burned badly enough that the fire almost looks like the cause of death.

It was not.

A strip of black cloth covered his mouth. A metal tag hung from his neck:

01]],
                note = 'Rusk was placed here after death.'
            },
            fire_report = {
                label = 'Read the fire report', shortTitle = 'FIRE REPORT',
                hint = "Rusk signed every inspection in Sandy. His last one never made it inside. Check the mailbox at the front fence.",
                body = [[SANDY SHORES FIRE INSPECTION

IGNITION: 2:08 AM
CAUSE: ACCIDENTAL
INVESTIGATOR: ELIAS RUSK

Someone had written beneath it:

"WRONG FIRE.
WRONG HOUSE.
SAME LIAR."]],
                note = '2:08 AM is being emphasized deliberately.'
            },
            burned_photo = {
                label = 'Examine the burned photograph', shortTitle = 'THE PHOTOGRAPH', optional = true,
                hint = "The report mentions a photograph that was never logged. Ash keeps the edges of paper.",
                prerequisites = { 'fire_report' },
                body = [[Eight people stood in front of the Sandy motel.

Seven faces were scratched out.

The eighth had been cut from the photograph completely.

On the back:

"HE COUNTED EIGHT.
HE ONLY BURIED SEVEN."]],
                note = 'Someone wants you counting.'
            },
            bell = {
                label = 'Examine the old bell', shortTitle = 'THE BELL',
                hint = "No soot on it, the card said. Something behind the house that the fire refused to touch.",
                prerequisites = { 'rusk_body', 'fire_report' }, scare = 'bell',
                body = [[An old service bell sits untouched among the ash behind the house.

There is no soot on it.

You touch it. It rings once.

A black card beneath it reads:

"THE FIRST ONE LIED WITH FIRE.

THE SECOND LIED TO GOD."]],
                note = 'The trail points toward the church.'
            }
        }
    },

    [2] = {
        id = 'church', number = '02', title = 'NO ONE WAS BURIED HERE',
        location = 'Church / Root Cellar',
        intro = 'Eight funerals. Eight graves. Zero bodies.',
        requiredEvidence = { 'vale_body', 'burial_ledger', 'fresh_coffin', 'nova_bible', 'motel_key' },
        completionText = 'EIGHT FUNERALS.\nZERO BODIES.\n\nTHEY WERE NEVER BURIED.\nTHEY WERE KEPT.',
        nextHint = 'ROOM 08',
        placeHint = 'The key fob belongs to the motel. Room eight is not on their board.',
        evidence = {
            vale_body = {
                label = 'Examine Father Vale', shortTitle = 'FATHER GIDEON VALE',
                hint = "A priest is not put on display where he preached. He is underneath it: the root cellar below the church. Follow the blood.",
                body = [[FATHER GIDEON VALE

Former church administrator.

His wrists were bound above him behind the altar. His shoes are placed neatly beneath his body. Black cloth has been wrapped around his tongue.

Tag: 02

Carved into the altar:

"HE BURIED NAMES.
NOT PEOPLE."]],
                note = 'Vale was displayed where his congregation once watched him speak.'
            },
            burial_ledger = {
                label = 'Read the burial ledger', shortTitle = 'THE BURIAL LEDGER',
                hint = "Eight funerals, every one signed. Vale kept his books at the altar, among the candles.",
                body = [[Eight funerals were recorded during the week of the disappearances.

Every entry carries Vale's signature.

A hidden sheet lists all eight:

BODY RECEIVED: NO
IDENTITY VERIFIED: NO
NEXT OF KIN PRESENT: NO

At the bottom:

"THE DEAD WERE EASIER TO INVENT THAN TO HIDE."]],
                note = 'The church created burials for bodies it never received.'
            },
            fresh_coffin = {
                label = 'Inspect the fresh coffin', shortTitle = 'THE EMPTY COFFIN',
                hint = "Seven are covered in dust. The clean one was never buried. It waits with the others.",
                prerequisites = { 'burial_ledger' }, scare = 'coffin_knocks',
                body = [[Seven coffins are covered in dust.

The eighth was clean.

Untouched pending burial.

Inside: nothing.

The inner lid was deeply scratched. Four words were carved from inside the box:

"I WAS STILL AWAKE."]],
                note = 'The scratches are recent.'
            },
            nova_bible = {
                label = 'Open the marked Bible', shortTitle = "NOVA'S NOTE",
                hint = "A hollowed book hides best among a hundred others. Look for the one that is marked.",
                prerequisites = { 'vale_body', 'burial_ledger' },
                body = [[The Bible has been hollowed out.

Inside was a folded page signed NOVA:

"Eight funerals. Zero bodies.

Vale didn't bury the missing. He buried the question.

I opened every grave.

Nothing.

If the church didn't receive them, somebody kept them somewhere else."]],
                note = 'Someone named Nova investigated this years ago.'
            },
            motel_key = {
                label = 'Take the motel key', shortTitle = 'ROOM 08',
                hint = "Something was left hanging behind the coffin. You were meant to find it last.",
                prerequisites = { 'vale_body', 'burial_ledger', 'fresh_coffin', 'nova_bible' },
                body = [[An old motel key hung behind the coffin.

ROOM 08

A strip of paper was attached:

"THEY WERE NEVER BURIED.
THEY WERE KEPT."

On the reverse:

"ROOM EIGHT DOES NOT EXIST."]],
                note = 'The trail points toward the motel.'
            }
        }
    },

    [3] = {
        id = 'motel', number = '03', title = 'ROOM EIGHT DOES NOT EXIST',
        location = 'Motel / Underground Cells',
        intro = 'The room upstairs is a distraction. The real room is underneath it.',
        requiredEvidence = { 'venn_body', 'room_scratches', 'underground_cells', 'cell_eight', 'motel_recorder', 'hospital_wristband' },
        completionText = 'EIGHT PEOPLE WENT DOWNSTAIRS.\n\nNONE CAME BACK UP.',
        nextHint = '2:08 AM. THE DEAD HAVE TWO NAMES.',
        placeHint = 'A hospital wristband. The ward that printed it would know the name.',
        evidence = {
            venn_body = {
                label = 'Examine Mara Venn', shortTitle = 'MARA VENN',
                hint = "The key in your pocket says 08. Start with the room that does not exist.",
                body = [[MARA VENN

Former motel owner.

Her body sat upright in a chair. Her hands were tied behind it. A black bag covered her head.

03 was painted on the wall behind her.

Pinned to her chest was a registration card:

GUEST: NO NAME
ROOM: 08
CHECK OUT: NEVER]],
                note = 'Venn owned the motel when the eight disappeared.'
            },
            room_scratches = {
                label = 'Inspect the bed frame', shortTitle = 'UNDER THE BED',
                hint = "Eight people slept in that room. People write where the cleaners never look.",
                body = [[The room looks clean.

Under the bed frame are eight sets of scratches: names, dates, tally marks.

One sentence appears over and over:

"DO NOT LET THEM TAKE YOU DOWNSTAIRS."]],
                note = 'The motel room was connected to something below it.'
            },
            underground_cells = {
                label = 'Examine the secret entry', shortTitle = 'THE HALL',
                hint = "The scratches say downstairs. The way down starts upstairs, behind something that should not be where it is.",
                prerequisites = { 'room_scratches' },
                body = [[Upstairs Storage Room.

A mirrior is placed in a weird spot.

Tally marks coveed the far wall and stop suddenly where a dark stain begins.

The basement was never abandoned.]],
                note = 'The original eight were held here.'
            },
            cell_eight = {
                label = 'Inspect Basement', shortTitle = 'CELL TWO',
                hint = "Follow the tally marks down. They stop where the stain begins.",
                prerequisites = { 'underground_cells' },
                body = [[Carved deep into the wall:

"NOVA FOUND US."

Underneath:

"HE CAME TOO LATE."

Lower down, barely scratched into the concrete:

"THEY MOVED THE OTHERS.
I CAN STILL HEAR THEM."]],
                note = 'Nova reached this room after the victims were moved from room 32'
            },
            motel_recorder = {
                label = 'Play the recorder', shortTitle = 'THE COUNT',
                hint = "Whoever carved those words counted the eight. The count was recorded, down here with them.",
                prerequisites = { 'cell_eight' }, scare = 'whisper',
                body = [[The recorder begain with heavy breathing.

"They moved them before sunrise.
Eight people went downstairs.
None came back up.
I know because I counted.
I wish I hadn't."

A second voice whispers from farther away:

"Stop counting."

The tape ends.]],
                note = 'The second voice was nowhere near the microphone.'
            },
            hospital_wristband = {
                label = 'Take the hospital wristband', shortTitle = '2:08 AM',
                hint = "A hospital band does not belong in a motel. The carvings say they were moved out of room 32: upstairs, far end of the walkway. A pill bottle still sits on the table in there. The band is under it.",
                prerequisites = { 'motel_recorder' },
                body = [[A hospital wristband was laying on a table.

The patient's name had been cut away.

TIME OF DEATH: 2:08 AM

The date matches the night of the disappearances.

On the back:

"ASK WHO SIGNED THEM DEAD."]],
                note = 'The next lie was written at the hospital.'
            }
        }
    },

    [4] = {
        id = 'hospital', number = '04', title = 'THE DEAD HAVE TWO NAMES',
        location = 'Hospital Morgue',
        intro = 'The perfect disappearance does not hide the body. It gives the body another name.',
        requiredEvidence = { 'harrow_body', 'transfer_records', 'false_identities', 'nova_body_bag', 'train_manifest' },
        completionText = 'THEY ERASED THE DEAD TWICE.\n\nFIRST THE BODY.\nTHEN THE NAME.',
        nextHint = 'THE TRAIN NEVER CAME.',
        placeHint = 'The manifest was stamped at the station ticket window. The stamp there never moved past 2:08.',
        evidence = {
            harrow_body = {
                label = 'Examine Dr. Harrow', shortTitle = 'DR. LENORA HARROW',
                hint = "A medical examiner would be laid out on her own table.",
                body = [[DR. LENORA HARROW

Former medical examiner.

Her body lies on an autopsy table. Every identification tag has been removed except one:

04

Eight blank toe tags surround her head.

Across the steel table:

"NAME THEM."]],
                note = 'Harrow signed the records tied to the missing eight.'
            },
            transfer_records = {
                label = 'Read the transfer records', shortTitle = 'TRANSFERRED',
                hint = "Eight transfers before sunrise. Transfers leave paperwork, and paperwork gets filed in the archive room.",
                body = [[Eight bodies were supposedly transferred out of Sandy before sunrise.

The hospitals exist.

The ambulance numbers do not.

Neither do the drivers.

All eight forms were created at exactly 2:08 AM.]],
                note = 'The transfers happened only on paper.'
            },
            false_identities = {
                label = 'Open the sealed envelopes', shortTitle = 'EIGHT FALSE NAMES',
                hint = "Eight death certificates for eight strangers, sealed. Harrow kept them in the downstairs office off the corridor, not with the dead.",
                prerequisites = { 'transfer_records' },
                body = [[Eight envelopes. Each contains a name, birth date, death certificate and fabricated next of kin.

None belong to the people who disappeared.

The victims were erased twice:

First physically.
Then legally.]],
                note = 'Harrow replaced eight missing people with eight unrelated deaths.'
            },
            nova_body_bag = {
                label = 'Open the ringing body bag', shortTitle = 'NOVA',
                hint = "Listen. Something is ringing on the trolley by the morgue sink, a few steps from Harrow's table. Follow the sound.",
                prerequisites = { 'false_identities' }, scare = 'phone_ring',
                body = [[A phone rings from inside the body bag on the trolley.

There is no phone.

Only the bag.

The toe tag reads:

NOVA

You open the bag.

Empty.

Written inside the plastic:

"YOU ARE LOOKING FOR A DEAD MAN."]],
                note = 'Someone wants you to believe Nova is dead.'
            },
            train_manifest = {
                label = 'Take the train manifest', shortTitle = 'THE DEPARTURE',
                hint = "Dead men do not buy tickets. The proof was kept where the living check in: the front desk in reception, by the entrance.",
                prerequisites = { 'nova_body_bag' },
                body = [[Eight passengers supposedly left Sandy the morning after the disappearances.

Every ticket uses the same serial number.

Every one was stamped by SAMUEL CROWE.

Departure: 2:16 AM.

No train stopped in Sandy that morning.]],
                note = 'The next lie was a departure that never happened.'
            }
        }
    },

    [5] = {
        id = 'station', number = '05', title = 'THE TRAIN NEVER CAME',
        location = 'Train Station',
        intro = 'The easiest way to make a missing person disappear is to convince everyone they left willingly.',
        requiredEvidence = { 'crowe_body', 'frozen_clock', 'eight_suitcases', 'crowe_letter', 'fake_departure', 'marina_key' },
        completionText = 'NOBODY LEFT SANDY.\n\nTHE TICKETS WERE REAL.\nTHE TRAIN WAS NOT.',
        nextHint = 'WHAT COULD NOT BE BURNED WAS THROWN INTO THE WATER.',
        placeHint = 'A marina key on a cork float. Sheriff Mercer kept his office by the water.',
        evidence = {
            crowe_body = {
                label = 'Examine Samuel Crowe', shortTitle = 'SAMUEL CROWE',
                hint = "A clerk dies where he stamped his tickets. Near the platform.",
                body = [[SAMUEL CROWE

Former station clerk.

His body hung near the platform. A punched ticket has been forced into his pocket.

Tag: 05

The departure board behind him read one destination:

NOWHERE]],
                note = 'Crowe created the records that made the victims appear to leave.'
            },
            frozen_clock = {
                label = 'Inspect the ticket window', shortTitle = '2:08',
                hint = "Crowe stamped every ticket at his window. The stamp never moved past the minute they started.",
                body = [[The clerk's time stamp at the ticket window is jammed at 2:08.

Every ticket stamped that night carries the same minute.

Scratched into the counter beside it:

"THIS IS WHEN THEY STARTED CLEANING."]],
                note = '2:08 may mark the beginning of the cover-up, not the deaths.'
            },
            eight_suitcases = {
                label = 'Search the eight suitcases', shortTitle = 'THE LUGGAGE',
                hint = "Travellers who never left still needed luggage. Eight bags, lined up like a departure.",
                prerequisites = { 'crowe_body' },
                body = [[Eight suitcases sat in a perfect line.

Inside were wallets, clothing, medicine, photographs and motel receipts belonging to the missing.

The eighth suitcase contained only wet dirt.

Nobody packed these bags to travel.]],
                note = 'The luggage was staged to make the departures believable.'
            },
            crowe_letter = {
                label = "Read Crowe's letter", shortTitle = 'I ONLY CHANGED PAPER',
                hint = "Crowe knew he was next. A man like that writes it down and leaves it where a clerk keeps his papers.",
                prerequisites = { 'eight_suitcases' },
                body = [["I saw what they did.

I told myself I never touched anyone.
I only changed paper.

That was the lie I lived with.

Paper can bury somebody just as deep as dirt.

If you're reading this, then he found me first."]],
                note = 'Crowe knew someone was hunting the people involved.'
            },
            fake_departure = {
                label = 'Pick up the dropped ticket', shortTitle = 'NO TRAIN',
                hint = "The manifest says 2:16. Somebody dropped a ticket on the station floor. Pick it up.",
                prerequisites = { 'train_manifest' }, scare = 'train_horn',
                body = [[A ticket, dropped on the station floor.

Same serial number as the eight in the manifest. Stamped by Crowe.

DEPARTURE: 2:16 AM

The timetable on the wall has no train at 2:16 AM.
No passenger service. No freight stop either.

Crowe invented a departure for a train that never came.]],
                note = 'A horn sounds after you finish reading. No train appears.'
            },
            marina_key = {
                label = 'Take the marina key', shortTitle = 'THE WATER',
                hint = "The eighth suitcase held only wet dirt. Dig through it.",
                prerequisites = { 'crowe_letter', 'fake_departure' },
                body = [[Inside the final suitcase was a rusted chain, still wet, and a marina key.

Attached:

"WHAT COULD NOT BE BURNED
WAS THROWN INTO THE WATER."]],
                note = 'The trail moves to the marina.'
            }
        }
    },

    [6] = {
        id = 'marina', number = '06', title = 'THE WATER KEPT EVERYTHING',
        location = 'Boat House / Marina',
        intro = 'The lake did not destroy the evidence. It preserved it.',
        requiredEvidence = { 'mercer_body', 'evidence_boxes', 'weighted_cache', 'mercer_tape', 'dock_message', 'university_file' },
        completionText = "THE SHERIFF DIDN'T CLOSE THE CASE.\n\nHE DROWNED IT.",
        nextHint = 'NOVA WAS HERE.',
        placeHint = 'The file carries the university archive stamp. Nova studied there. The archive is the university itself. Start at the pond on the campus grounds.',
        evidence = {
            mercer_body = {
                label = 'Examine Abel Mercer', shortTitle = 'SHERIFF ABEL MERCER',
                hint = "A sheriff with a chain on his ankle does not sink. He floats out past the rocks, north of the long dock.",
                body = [[ABEL MERCER

Former Sheriff.

His body was found floating above the water. A heavy chain was wrapped around one ankle.

Tag: 06

Pinned to his uniform:

TRANSIENT DEPARTURE

The same phrase appears in the old missing-person reports.]],
                note = 'Mercer controlled the case and the physical evidence.'
            },
            evidence_boxes = {
                label = 'Search the dumped files', shortTitle = 'DESTROYED',
                hint = "Mercer kept an office by the water: the boat rental, at the west end of the marina. What he claimed to destroy never made it back inside. It was left by the bin at the fence.",
                body = [[Old police evidence files, dumped by the bin outside the office.

One has been resealed.

Inside are eight evidence bags.

Every bag is stamped:

DESTROYED

None of them are empty.]],
                note = 'Mercer kept what he claimed to destroy.'
            },
            weighted_cache = {
                label = 'Inspect the trash can', shortTitle = 'THE LAKE',
                hint = "Not everything fit in evidence bags. The rest went in a bin, in the restroom of the boat house across the marina.",
                prerequisites = { 'evidence_boxes' },
                body = [[A old folder held IDs, motel keys, church paperwork, medical tags and photographs.

Objects from every lie discovered so far.

The water damaged them.

It did not erase them.]],
                note = 'The cover-up converges here.'
            },
            mercer_tape = {
                label = "Play Mercer's tape", shortTitle = "THAT'S HOW PLACES ROT",
                hint = "Mercer recorded his own conversations. The tape is upstairs in the boat house, on the floor among his wine.",
                prerequisites = { 'weighted_cache' },
                body = [[Mercer:

"People disappear. People move. People don't ask questions. That's how places survive."

Another voice answers.

Nova:

"No. That's how places rot."]],
                note = 'Nova confronted Mercer directly.'
            },
            dock_message = {
                label = 'Listen beneath the dock', shortTitle = '3 - 3 - 2',
                hint = "Three, three, two. Go out on the long dock with the telescope at night and listen under the boards.",
                prerequisites = { 'mercer_tape' }, scare = 'dock_knocks',
                body = [[Three knocks.
Pause.
Three knocks.
Pause.
Two knocks.

Eight total.

There is nothing beneath the dock.

On the underside of the boards:

"HE FOUND THE ARCHIVE."]],
                note = 'The pattern totals eight.'
            },
            university_file = {
                label = 'Take the archive file', shortTitle = 'NOVA',
                hint = "HE FOUND THE ARCHIVE, the boards said. A sealed file is waiting back in the boat house, on the reception desk.",
                prerequisites = { 'dock_message' },
                body = [[A sealed police file carries a university archive stamp.

ACCESS NAME: NOVA
DATE: EIGHT YEARS AGO

Handwritten beneath:

"IF YOU WANT TO KNOW WHO ERASED HISTORY,
FIND THE PERSON WHO WRITES IT."]],
                note = "Nova's investigation continued into Sandy's archives."
            }
        }
    },

    [7] = {
        id = 'university', number = '07', title = 'NOVA WAS HERE',
        location = 'University / Archive',
        intro = 'Everything you discovered was discovered once before.',
        requiredEvidence = { 'kade_body', 'archive_wall', 'nova_journal', 'nova_last_recording', 'compound_photo', 'fresh_message' },
        completionText = "NOVA DIDN'T LEAD YOU HERE.\n\nSOMEBODY IS USING HIS CORPSE AS A MAP.",
        nextHint = 'COME FINISH THE STORY.',
        placeHint = 'The photograph shows the illegal garage past the east edge of town, by the gas station. Eight chairs in the pit beneath it.',
        evidence = {
            kade_body = {
                label = 'Examine Evelyn Kade', shortTitle = 'EVELYN KADE',
                hint = "The archivist was left in water, eyes covered. Not the lake this time. The pond on the campus grounds, the one ringed with lamps.",
                body = [[PROFESSOR EVELYN KADE

Former municipal archivist.

Her body laid inside the water. Her eyes are covered. Her mouth is sewn shut.

Tag: 07

A label beneath her:

EDITOR]],
                note = 'Kade controlled the public history of the disappearances.'
            },
            archive_wall = {
                label = 'Study the evidence wall', shortTitle = 'SOMEONE GOT HERE FIRST',
                hint = "Nova pinned everything he knew to one wall of the classroom with the projector.",
                prerequisites = { 'kade_body' },
                body = [[The burning house. The church. The motel. The morgue. The station. The marina.

Names. Dates. Reports. Maps. Connections.

Everything you discovered tonight is already on this wall.

The investigation is old.]],
                note = 'Nova solved most of this years before you arrived.'
            },
            nova_journal = {
                label = "Read Nova's journal", shortTitle = 'EIGHT YEARS AGO',
                hint = "A man who pins his case to a wall keeps his journal within reach of it. He wrote it at the one table a whole room of seats faces, and let the coffee go cold.",
                prerequisites = { 'archive_wall' },
                body = [[Nova's final page:

"Rusk. Vale. Venn. Harrow. Crowe. Mercer. Kade.

Seven names.

There is an eighth.

The eighth never signs anything. He gives the order and somebody else puts their name on it.

I found where they took the bodies.

If I'm right, this ends tomorrow."]],
                note = 'Nova disappeared before tomorrow came.'
            },
            nova_last_recording = {
                label = "Play Nova's final recording", shortTitle = 'DO NOT FOLLOW THE NOTES',
                hint = "The journal ends mid-sentence. Nova finished the thought out loud, on tape. Ground floor, east side of the building: on the floor by the bin, under the wall clock.",
                prerequisites = { 'nova_journal' }, scare = 'archive_bell',
                body = [[Nova:

"If this reaches anybody, do not follow the notes.

Someone knows what I found.

Someone has been moving behind me all night.

I thought I was tracking the case.

I think the case is tracking me."

A bell rings.

"No. No, no, no—"

The recording ends.]],
                note = 'Nova knew someone was following him.'
            },
            compound_photo = {
                label = 'Examine the compound photograph', shortTitle = 'WHERE THEY TOOK THE EIGHT',
                hint = "I found where they took the bodies, he wrote. He photographed it. The photograph is in the trophy cabinet by the lecture hall doors, at the north end of the ground floor.",
                prerequisites = { 'nova_last_recording' },
                body = [[A photograph shows the Compound.

Nova wrote:

"THIS IS WHERE THEY TOOK THE EIGHT."

Another sentence sits beneath it in different handwriting and fresh ink:

"THIS IS WHERE I TOOK NOVA."]],
                note = 'The second message could not have been written eight years ago.'
            },
            fresh_message = {
                label = 'Read the fresh message', shortTitle = 'COME FINISH THE STORY',
                hint = "The paint is wet. Whoever wrote it is still here. The wall under the east stairs, by the bin.",
                prerequisites = { 'compound_photo' }, scare = 'archive_blackout',
                body = [[The lights die.

When they return, wet paint is on the wall:

"SEVEN LIES.
SEVEN BODIES.
ONE LEFT.

COME FINISH THE STORY."

Beneath it is the outline of a brass bell.]],
                note = 'Whoever is doing this is here now.'
            }
        }
    },

    [8] = {
        id = 'compound', number = '08', title = 'THE LAST WITNESS',
        location = 'The Illegal Garage',
        intro = 'You are no longer investigating a crime scene. You have entered the place where the crime was designed.',
        requiredEvidence = { 'eight_chairs', 'surveillance_wall', 'nova_body', 'voss', 'voss_confession', 'final_bell', 'last_message' },
        completionText = 'NOW YOU KNOW.\n\nTHAT MAKES YOU THE LAST WITNESS.',
        evidence = {
            eight_chairs = {
                label = 'Examine the eight chairs', shortTitle = 'EIGHT CHAIRS',
                hint = "Eight chairs facing a wall. Start there. The garage has a secret floor beneath it, past the vault doors.",
                body = [[Eight chairs face an empty wall.

Seven contain evidence from the previous scenes.

01 Fire report
02 Funeral ledger
03 Motel key
04 Death certificate
05 Train ticket
06 Evidence bag
07 Archive file

Chair 08 is empty.

A card rests on it:

"HE IS STILL BREATHING."]],
                note = 'The eighth conspirator has not been killed yet.'
            },
            surveillance_wall = {
                label = 'Inspect the computer', shortTitle = 'YOU WERE WATCHED',
                hint = "Somebody watched every step you took tonight. The screens are above you.",
                prerequisites = { 'eight_chairs' },
                body = [[Photographs cover the screen.

You at the burning house.
You entering the church.
You outside the motel.
You in the morgue.
You at the station.
You on the dock.
You inside the archive.

Someone followed the entire investigation.

One empty frame is labeled:

08 - WITNESS]],
                note = 'The investigation itself was part of the plan.'
            },
            nova_body = {
                label = 'Examine the hanging body', shortTitle = 'NOVA',
                hint = "One body hangs apart from the rest.",
                prerequisites = { 'surveillance_wall' },
                body = [[One body hangs separately.

Old boots. Weathered jacket. Camera. Recorder.

A rusted plate hangs around the neck:

NOVA

The remains are years old.

Nova did not leave tonight's notes.
Nova did not kill the seven.

Somebody has been speaking with a dead man's voice.]],
                note = 'Nova has been dead since the original investigation.'
            },
            voss = {
                label = 'Examine the eighth chair', shortTitle = 'HARLAN VOSS',
                hint = "Go back to the eighth chair.",
                prerequisites = { 'nova_body' },
                body = [[Chair 08 is no longer empty.

HARLAN VOSS
Owner of the Compound.

Alive.
Barely.

Bound to the chair with a tag around his neck:

08

Unlike the others, the number has not been crossed out.]],
                note = 'Voss is the eighth conspirator.'
            },
            voss_confession = {
                label = "Play Voss's confession", shortTitle = 'THE EIGHTH MAN',
                hint = "Voss already said it once, on tape. It is beside him.",
                prerequisites = { 'voss' },
                body = [[Voss:

"We didn't mean to kill eight.

I told them what to do.
Rusk burned it.
Vale made graves.
Venn gave us the rooms.
Harrow made names.
Crowe made departures.
Mercer handled evidence.
Kade erased the records.

Nova found us.

I had him brought here.
I watched him die.

I thought that ended it."

Voss looks past you.

"No.
Please.
Not the bell."]],
                note = "Voss ordered the cover-up and Nova's murder."
            },
            final_bell = {
                label = 'Ring the final bell', shortTitle = 'THE BELLMAN',
                hint = "A button on the pit wall, wired to an old bell. You know what it does by now.",
                prerequisites = { 'voss_confession' }, scare = 'final_blackout',
                body = [[An old bell rests on the near the wall.

Beneath it:

"EIGHT PEOPLE ERASED THE DEAD.
SEVEN HAVE CONFESSED.
ONE REMAINS.

DO YOU THINK CONFESSION MEANS FORGIVENESS?"

The bell rings.

The lights go out.

A struggle.
A wet impact.
Silence.

When the lights return, Voss is dead.

08 has been crossed out.]],
                note = 'The Bellman completed the sequence while you were in the room.'
            },
            last_message = {
                label = 'Read the last message', shortTitle = 'THE LAST WITNESS',
                hint = "Get up. Look around the room.",
                prerequisites = { 'final_bell' },
                body = [[The bell is gone.

A final card rests on Chair 08:

"NOW YOU KNOW.

THAT MAKES YOU THE LAST WITNESS."

Underneath:

"ASK NOVA WHAT HAPPENED TO THE LAST ONE."

You turn toward Nova's body.

The rope is still hanging.
The identification plate is on the floor.

The body is gone.]],
                note = 'There is no explanation for how Nova disappeared.'
            }
        }
    }
}

function M8Story.GetEvidence(evidenceId)
    for chapterIndex, chapter in pairs(M8Story.Chapters) do
        if chapter.evidence and chapter.evidence[evidenceId] then
            return chapterIndex, chapter.evidence[evidenceId], chapter
        end
    end
    return nil, nil, nil
end

function M8Story.HasPrerequisites(progress, evidence)
    if not evidence or not evidence.prerequisites then return true end
    for _, evidenceId in ipairs(evidence.prerequisites) do
        if not progress.evidence[evidenceId] then return false end
    end
    return true
end
