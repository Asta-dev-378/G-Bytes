// word_wheel_screen.dart
// 8 outer letters + 1 center letter. Find words of 3+ letters, all must include center.

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'brain_game_shared.dart';

class WordWheelScreen extends StatefulWidget {
  const WordWheelScreen({super.key});
  @override
  State<WordWheelScreen> createState() => _WordWheelScreenState();
}

class _WordWheelScreenState extends State<WordWheelScreen> {
  // ignore: unused_field
  static const _gameId = 'word_wheel';

  BrainDifficulty? _difficulty;
  bool _countdownDone = false;

  late String _center;
  late List<String> _outer;
  final List<int> _selected = []; // indices: 0=center, 1-8=outer
  String _currentWord = '';
  final List<String> _found = [];
  bool _invalid = false;
  int _score = 0;

  int _secondsLeft = 90;
  Timer? _timer;
  bool _gameOver = false;

  Color get _accent => const Color(0xFFEC4899);

  // ---------------------------------------------------------------------------
  // MASSIVE WORD BANK
  // Categories: 3-letter core, animals, birds, reptiles, fish, insects,
  // places, names (male & female), food & drink, body, emotions, colors,
  // nature & weather, plants, toys & games, sports, phobias, science,
  // music & arts, transport, clothing, household, school, materials, jobs,
  // adjectives, verbs, 4-letter core, 5-letter, 6-letter+
  // ---------------------------------------------------------------------------
  static const _wordBank = <String>{

    // ── 3-LETTER ──────────────────────────────────────────────────────────────
    'ace','ache','act','add','age','ago','aid','aim','air','ale','all','ant','ape',
    'apt','arc','are','ark','arm','art','ash','ask','ate','awe','axe','aye',
    'ban','bar','bat','bay','bed','bee','bet','big','bit','bog','bow','box','boy',
    'bud','bug','bun','bus','but','cab','can','cap','car','cat','cob','cod','cog',
    'cop','cow','cry','cue','cup','cut','dab','dam','den','dew','dig','dim','dip',
    'dog','dot','dry','dub','due','dug','duo','dye','ear','eat','eel','egg','ego',
    'elk','elm','end','era','eve','ewe','eye','fad','fan','far','fat','fee','few',
    'fig','fit','fly','fog','foe','fox','fry','fun','fur','gag','gap','gas','gel',
    'gem','gig','gin','gnu','gob','got','gum','gun','gut','guy','had','ham','hat',
    'hay','hen','hit','hog','hop','hot','how','hub','hue','hug','hum','ice','ill',
    'imp','ink','inn','ion','ire','ivy','jab','jag','jam','jar','jaw','jay','jet',
    'jot','joy','jug','jut','keg','kin','kit','lab','lag','lap','law','lax','lay',
    'lea','led','leg','lid','lip','log','lot','low','mad','map','mat','may','mob',
    'mom','mud','mug','nab','nag','nap','nit','nor','nun','oak','oar','oat','odd',
    'ode','off','oil','old','opt','orb','out','own','pad','pal','pat','paw','pay',
    'pea','peg','pen','pie','pin','pit','pop','pry','pub','pun','pup','rad','ram',
    'rat','raw','ray','ref','rep','rev','rid','rip','rob','rod','row','rub','rum',
    'rut','sag','sap','sat','saw','say','set','sew','shy','sin','sip','sir','sky',
    'sly','sob','son','spa','spy','tab','tag','tap','tar','tax','tin','tip','top',
    'tow','toy','try','two','vat','vow','war','was','way','web','who','why','win',
    'wit','wok','won','woo','yak','yen','yes','yet','yew','zen',

    // ── 3-LETTER ANIMALS ─────────────────────────────────────────────────────

    // ── 4-LETTER CORE ─────────────────────────────────────────────────────────
    'able','acid','acre','aged','aide','akin','aloe','ante','anti','apex','arch',
    'area','atom','axle','back','bail','bait','bake','bald','bale','ball','balm','band',
    'bane','bang','bare','bark','barn','base','bash','bask','bead','beam','bean','bear',
    'beat','beck','been','belt','bind','bird','bite','blot','blow','blue','blur','bold',
    'bolt','boom','boon','boot','bore','born','both','brag','bray','bred','brew','brow',
    'buff','bulb','bulk','bull','bump','burn','burp','cafe','cage','cake','calf','call',
    'calm','came','cane','cape','card','care','cart','case','cash','cast','cave','cell',
    'chef','cite','clad','clam','clap','clay','clot','club','clue','coal','coat','coil',
    'coin','cold','colt','cone','cook','cool','cord','core','corn','crag','damp','dare',
    'dark','dash','data','dawn','dead','deaf','deal','dean','debt','deck','deed','deem',
    'deer','deft','dens','desk','dial','dice','died','diet','dime','dire','dirt','disc',
    'dish','disk','dome','doom','dose','dove','down','drab','drag','draw','drew','drip',
    'drop','drum','dual','dull','dumb','dump','dusk','dust','dyer','each','earl','earn',
    'ease','east','echo','edge','edit','emit','epic','even','ever','evil','exam','face',
    'fact','fade','fail','fair','fake','fall','fame','fare','farm','fast','fate','fear',
    'feed','feel','feet','fell','felt','file','fill','film','find','fine','fire','firm',
    'fish','fist','five','flag','flat','flaw','fled','flew','flip','flow','foam','fold',
    'folk','fond','food','fool','foot','ford','fore','fork','form','fort','foul','four',
    'free','frog','from','fuel','full','fund','fuse','gale','game','gang','gate','gave',
    'gaze','gear','gild','girl','give','glad','glow','glue','goal','goes','gold','gone',
    'good','grab','gray','grew','grid','grim','grin','grip','grow','gulf','gulp','gust',
    'half','hall','hand','hang','harm','harp','hate','have','hawk','haze','head','heal',
    'heap','heat','heel','held','helm','help','herb','herd','hero','hide','high','hill',
    'hint','hire','hold','hole','home','hook','hope','horn','host','hour','huge','hull',
    'hump','hunt','hurt','idea','idle','idol','iris','isle','item','jade','jail','jeer',
    'join','joke','jolt','jump','just','keen','keep','kill','kind','king','kiss','knot',
    'lack','lake','lamp','land','lane','lark','last','late','lead','leaf','leak','lean',
    'leap','left','lend','less','life','lift','like','lime','limp','line','link','lion',
    'list','live','load','loan','lock','loft','lone','long','look','loop','lore','lose',
    'loss','love','luck','lung','lure','lurk','made','maid','mail','main','make','mall',
    'malt','mark','mash','mask','mass','mast','mate','maze','mean','meat','meet','melt',
    'mesh','mild','mile','milk','mill','mind','mine','mint','mire','miss','mist','mode',
    'mole','mood','moon','more','most','moth','move','much','muck','mule','must','nail',
    'name','nape','need','nest','news','next','nice','nine','node','none','noon','norm',
    'nose','note','null','oath','obey','odds','open','oven','over','owed','pace','page',
    'paid','pain','pair','pale','pave','pawn','peak','peel','peer','pest','pick','pile',
    'pine','pink','pipe','plan','play','plot','plow','plod','plug','plus','poem','poet',
    'pole','poll','pond','pool','port','pose','post','pour','pray','prey','prod','prop',
    'pull','pump','pure','push','quit','race','rack','rage','raid','rail','rain','ramp',
    'rank','rate','rave','read','real','reap','reed','reef','reel','rent','rest','rice',
    'rich','ride','ring','riot','ripe','rise','risk','road','roam','roar','rode','role',
    'roll','roof','room','rope','rose','rove','rude','ruin','rule','rush','rust','safe',
    'sage','sail','sake','salt','same','sand','sane','sang','sank','save','scan','scar',
    'seal','seam','sear','seed','seek','seem','seen','self','sell','send','sent','shed',
    'ship','shoe','shop','shot','show','shut','side','sigh','silk','sill','sing','sink',
    'site','size','skin','skip','slam','slap','sled','slim','slip','slot','slow','slug',
    'snap','snow','soap','sock','sofa','soil','sold','some','song','sort','soul','soup',
    'sour','span','spin','spit','spot','spur','stab','star','stay','stem','step','stir',
    'stop','stub','stud','suck','suit','sulk','swam','swan','swap','swim','tale','tall',
    'tame','tang','tank','task','taut','team','tear','tell','tend','tent','test','tilt',
    'time','tire','toad','told','toll','tomb','tone','took','tool','tour','town','trap',
    'tray','tree','trim','trio','trip','trod','true','tube','tune','turf','turn','tusk',
    'twin','type','ugly','undo','unit','upon','urge','used','vain','vale','vast','veer',
    'veil','vein','vile','vine','void','vole','volt','wade','wage','wake','walk','wall',
    'wand','ward','warm','warp','wart','wary','wave','waxy','ways','weak','weal','wean',
    'wear','weed','week','well','went','were','west','wide','wild','will','wilt','wind',
    'wine','wing','wink','wire','wish','wisp','woke','wolf','womb','word','wore','work',
    'worm','worn','wove','wrap','wren','writ','yard','yawn','year','yell','yoga','yoke',
    'yore','your','zeal','zero','zinc','zone',

    // ── ANIMALS — MAMMALS ─────────────────────────────────────────────────────
    'giraffe','zebra','rhino','hippo','elephant','tapir','capybara','armadillo',
    'horse','mare','pony','donkey','stallion','goat','sheep','lamb','llama','alpaca','camel','kitten','puppy','rabbit','bunny','hamster','gerbil','chinchilla',
    'monkey','baboon','gorilla','chimp','bonobo','lemur','gibbon','marmoset','macaque',
    'dolphin','whale','narwhal','orca','porpoise','walrus','manatee','dugong','hedgehog','shrew','possum','opossum','skunk','raccoon','warthog',
    'kangaroo','wallaby','wombat','quokka','platypus','echidna','numbat','bandicoot',
    'caribou','reindeer','porcupine','aardvark','pangolin','anteater','kinkajou',

    // ── ANIMALS — BIRDS ──────────────────────────────────────────────────────
    'eagle','falcon','kite','osprey','vulture','condor','harrier','buzzard',
    'owl','heron','crane','stork','ibis','flamingo','pelican','egret','spoonbill',
    'parrot','macaw','cockatoo','toucan','hornbill','kingfisher','sunbird',
    'robin','sparrow','finch','warbler','starling','swallow','swift','martin',
    'crow','raven','magpie','jackdaw','rook','chough','roller',
    'pigeon','quail','partridge','pheasant','grouse','turkey','peacock',
    'duck','goose','teal','mallard','cormorant','gannet','puffin','guillemot',
    'penguin','albatross','petrel','skua','gull','tern','plover','curlew','snipe',
    'woodpecker','nuthatch','dunnock','thrush','blackbird','linnet','siskin',
    'canary','budgie','lovebird','cockatiel','myna','lorikeet','kea','kiwi',
    'ostrich','rhea','cassowary','roadrunner',

    // ── ANIMALS — REPTILES & AMPHIBIANS ─────────────────────────────────────
    'snake','cobra','python','viper','adder','mamba','rattler','anaconda',
    'lizard','gecko','iguana','skink','chameleon','monitor','agama','anole',
    'crocodile','alligator','caiman','gharial',
    'turtle','tortoise','terrapin','newt','salamander','axolotl','caecilian',

    // ── ANIMALS — FISH & SEA ─────────────────────────────────────────────────
    'shark','salmon','trout','bass','carp','perch','pike','tuna','halibut',
    'herring','mackerel','sardine','anchovy','sole','plaice','flounder',
    'guppy','tetra','molly','betta','cichlid','clownfish','angelfish',
    'squid','octopus','cuttlefish','jellyfish','anemone','coral','nautilus',
    'lobster','crab','shrimp','prawn','barnacle','crayfish','krill',
    'oyster','mussel','scallop','snail','whelk','limpet','lamprey','sturgeon','stingray','manta','swordfish','marlin','sailfish',
    'seahorse','starfish','urchin','sponge',

    // ── ANIMALS — INSECTS ────────────────────────────────────────────────────
    'butterfly','dragonfly','damselfly','mayfly',
    'grasshopper','cricket','locust','mantis','katydid',
    'spider','tarantula','scorpion','tick','mite','centipede','millipede',
    'flea','aphid','silverfish','earwig','cockroach','termite','weevil',

    // ── PLACES — GEOGRAPHIC ───────────────────────────────────────────────────
    'mountain','valley','canyon','gorge','ravine','cliff','ridge','summit','plateau',
    'river','stream','brook','creek','lagoon','inlet','strait',
    'ocean','coast','shore','beach','island','peninsula','delta','estuary',
    'desert','tundra','taiga','steppe','savanna','prairie','meadow','wetland','swamp','marsh',
    'forest','jungle','rainforest','woodland','grove','orchard','garden','park','moor','heath',
    'volcano','crater','geyser','glacier','iceberg','fjord','atoll',
    'grotto','cavern','sinkhole','mesa','butte','dune','sandbar',

    // ── PLACES — HUMAN ────────────────────────────────────────────────────────
    'city','village','hamlet','suburb','district','county','state','province','nation',
    'street','avenue','alley','boulevard','highway',
    'bridge','tunnel','harbor','marina','wharf','pier','dock',
    'airport','station','terminal','depot',
    'school','college','university','library','museum','gallery','theater','cinema',
    'church','temple','mosque','shrine','cathedral','chapel','monastery','convent',
    'castle','palace','manor','mansion','cottage','cabin','hut','shelter',
    'hospital','clinic','pharmacy','surgery',
    'market','store','arcade','bazaar',
    'hotel','motel','hostel','resort','lodge','chalet',
    'stadium','arena','gym','court','pitch','track','rink',
    'bank','office','factory','warehouse','garage','workshop','studio',
    'prison','embassy','parliament','capitol','ranch','vineyard','stable','silo','quarry','refinery','plant','foundry',

    // ── NAMES — MALE ─────────────────────────────────────────────────────────
    'adam','alan','alex','allen','arlo','asher','austin','axel','bart','beau',
    'ben','blake','boris','brad','bram','brett','brian','brody','carl','carter',
    'chad','charlie','chase','clark','cole','colin','conor','craig','cyrus',
    'dale','daniel','dante','dave','derek','dion','dominic','dorian',
    'dylan','edgar','edward','elias','elijah','ellis','elton','eric','ethan','evan',
    'ezra','felix','finn','frank','fred','gabe','gavin','gene','george','glen',
    'grant','greg','hal','harry','hayden','hector','henry','hugo','hunter','ian',
    'ivan','jack','jake','james','jared','jasper','jeff','jesse','joel',
    'john','jonas','jose','josh','julian','justin','kai','kane','karl','keith',
    'ken','kent','kian','kyle','lance','lars','leo','levi','liam','logan','luca',
    'lucas','luke','marc','mario','matt','max','miles','neil',
    'nick','noel','nolan','omar','oscar','owen','paul','pedro','pete','phil',
    'quinn','ralph','rex','rhys','riley','roman','ross','rowan',
    'ryder','scott','sean','seth','simon','stefan','theo','thomas','tim','tom',
    'travis','trevor','troy','tyler','victor','walter','warren',
    'wyatt','zach','zane','aden','arno','asim','blade','brent','bryce','cody','colton','damon','devin','dex','diesel','duke','dustin',
    'emmett','gage','gareth','gil','gino','gordon','grady',
    'harris','haydn','holden','horatio','howie','igor','ike','imran',
    'indiana','indra','irwin','jarvis','jax','jed','jett','joaquin','joey','jude','juls','kaito','keane','keanu','keir','kells','kenji','kenzo','kieran','kimani','kirra','koda','kolby','kosta','lamar','lander','lanny','layne','leland','lemuel','lennon','lenny',
    'leon','leonel','leron','leroy','lester','lex','linton','lionel',
    'lobo','lonnie','lorcan','louie','lucius','lucky','ludovic','luiz',
    'lyall','mace','mack','marco','mason','maverick','maxim','maxwell',
    'micky','miller','milo','mitchell','mitch','monty','morgan','moses',
    'moss','murphy','nash','nero','niall','niels','nigel','nikolai','norbert',
    'norris','norton','nuno','odin','orion','oz','pascal','patch',
    'patton','paulo','paxton','payne','penn','pierce','pixel','porter','pranav',
    'prescott','prince','priya','quest','rafi','rahul','rajan','ramsey',
    'raoul','raphael','rashid','rawley','rebel','regan','reginald',
    'reid','remy','renaldo','renn','rhett','rick','ricky','rio','rishi',
    'roan','roarke','rodd','roddy','rodrigo','rollo','rolph','romero','ronan',
    'rory','rourke','rowdy','ruben','rufus','ryland','santo',
    'sawyer','sebastien','sergio','shawn','shelton','sherif','silas','silvio',
    'skyler','sloane','solomon','sorrel','spike','sterling','stig','stone',
    'storm','sully','tanner','tarl','tarquin','taylor','terrence','tobias',
    'toby','tomas','torsten','trenton','tripp','tristan','tucker','ulric',
    'vaughn','vince','vincenzo','vladek','walton','wayne','weston','wilder',
    'william','wilson','wylie','xander','xavier','yusuf','zander','zeke','zeus',

    // ── NAMES — FEMALE ────────────────────────────────────────────────────────
    'ada','adele','aida','aisha','alba','alexa','alice','alina','alma','amber',
    'amelia','amy','ana','andrea','anita','anna','annie','april','aria','ariel',
    'asha','ashley','astrid','athena','audrey','aurora','ava','avery','beatrice',
    'bella','bianca','bonnie','brenda','briar','brooke','camille','cara','carmen',
    'carol','cecilia','celia','charlotte','chloe','claire','clara','claudia',
    'crystal','daisy','dana','daniela','darcy','daria','delilah','diana',
    'donna','dora','eden','edith','elena','elisa','elise','ella','ellie','elsa',
    'emma','erin','esther','eva','evelyn','faith','faye','fiona','flora','freya',
    'gemma','georgia','gia','gina','grace','greta','hana','harriet','heather',
    'heidi','helen','holly','imogen','ines','ingrid','irene','isla','jasmin','jessica','jill','jodie','jolie','julia','juliet','june',
    'kaia','karen','keely','kelly','kira','laila','lara','laura','lauren','leah',
    'leila','lena','lily','linda','lisa','lola','luna','lydia','lyra','mabel',
    'maeve','maja','mara','margot','maria','marie','marta','mary',
    'matilda','maya','megan','mila','millie','mina','mira','miriam',
    'mona','nadia','nala','naomi','natalie','nell','nina','nora','nova','olivia',
    'orla','paige','paloma','pandora','paris','patricia','piper','polly','rachel',
    'raine','rebecca','rosie','ruby','ruth','sabrina','sadie',
    'sandra','sara','sarah','sasha','selena','sierra','silvia','simone','skye',
    'sofia','stella','summer','sylvia','tamara','tara','teresa','tess','tia',
    'tilda','tina','tori','valentina','vera','violet','vivian','wendy',
    'yara','yasmine','zara','zelda','zoe',
    'abril','acacia','adaeze','adira','adriana','agatha','aiko','ailsa',
    'ainsley','airi','aislinn','aiyana','akari','akeelah','akeira','aleina',
    'alena','alessa','alessia','alexia','alexis','alexus','alicia','alison','alissa',
    'aliya','alondra','alora','amara','amari','amaya','amira','amora','amya',
    'analise','anastasia','andrada','angelica','angeline','aniyah','annalise',
    'antonella','arabella','ariana','arianna','ariella','arin','ariya','arlie',
    'armani','arnica','arona','arwen','asella','ashira','ashlynn','ashton','asia',
    'astoria','asuka','aviana','ayanna','ayasha','aylin','ayra','azalea','azalia',
    'azara','azena','azul','azura','beatrix','belinda','berenice','bethany','blythe',
    'brea','bree','bret','brielle','brigid','brinna','britta','bronte','cambria',
    'camellia','capri','carlena','carlin','cass','cassidy','cassia','catalina',
    'catarina','cecile','celestine','celine','chara','charli','chelsie','cheri',
    'cheyenne','chiara','christy','ciana','cienna','cierra','clio','codie','corin',
    'cosima','courtney','cressida','cris','cyndal','cyndi','daena','dalila',
    'damaris','damia','dani','danna','daphne','darla','darline','davina','dayna',
    'deanna','deena','deja','delia','delice','demi','dena','denise','desiree',
    'diamond','dianna','dolce','dolly','dominique','dulce','elayna','eleanor','eleonora',
    'eleri','elfie','eliana','elina','elira','elisha','elita','eliza','elizabella',
    'ellery','elodie','eloise','elora','elvina','elwyn','emilia','emiliana',
    'emmy','enid','eowyn','esme','eulalia','euphemia','evita','fabiola','farida',
    'fatima','felicia','felicity','fernanda','fiorella','fleur','florentia',
    'floriana','fontaine','fran','francesca','francine','galena','galilea',
    'genevieve','georgette','gianella','gianna','ginger','giorgia','giovanna',
    'giulia','glenda','grecia','greer','guadalupe','gwen','gwyneth','hadassah',
    'hailey','haleigh','halia','halina','halsey','hanako','haya','hayley','hazel',
    'hema','henley','henna','hera','hestia','hilde','hina','honoria','hypatia',
    'iana','iara','idalia','ife','ilaria','iliana','imelda','imani','india','indy',
    'iolande','iona','irena','isadora','isidora','ivana','ivey','jaida','jaime',
    'jaina','jamila','janel','janelle','janiya','janna','jaqueline','jariya','jayla',
    'jaylin','jazmine','jeanne','jelena','jessamine','jianna','jocasta','johanna',
    'jonquil','josephine','josie','jovita','joya','kalani','kalinda','kalista',
    'kallista','kamille','kamina','karis','karla','karlie','kassia','katarina',
    'katelyn','katharina','katia','katje','katrina','kayleigh','keena','kendra',
    'kerry','kiana','kiara','kiersten','kiley','kimberly','kimiko','kinsley',
    'kiri','kirsten','kleo','kloe','komala','krista','kristel','kristie','kyara',
    'kylie','kyndall','kyoko','laci','lacinda','laetitia','laia','laine','laney',
    'larisa','larissa','lavinia','layah','layla','leana','leandra','leigh',
    'leina','lenora','leonie','leora','leslee','lexi','leyla','lia','liana','lianna',
    'lila','lilah','lilas','lima','linh','linne','liora','lissandra','lita','livvy',
    'lizbeth','lorena','loretta','lorin','lorraine','lottie','lovisa','lucia','luciana',
    'lucie','lucija','luella','lumi','lumina','luneth','luvena','lyda','lynnea',
    'maaria','machi','maddie','madelyn','madelynn','madina','maelle','magdalena',
    'mahalia','mahina','mai','maira','maite','malia','malika','malina','manon',
    'marcela','marcie','maren','marena','mariana','mariela','marielle','marilyn',
    'marinda','maris','marisol','maritza','marjorie','marlena','marley','marlowe',
    'marnie','marquita','marshia','marzena','masie','mathea','mathilda','mattea',
    'mave','mayan','mckayla','meagan','meg','meiko','melanie','melina','melinda',
    'mellisa','mercy','meredith','merina','meseret','mia','micaela','michaela',
    'micheline','milena','mirela','mirella','misty','mitzi','miyuki','moana','monique',
    'mora','morina','nadège','naia','nakita','nalani','naleena','nalini','namia',
    'narida','nashwa','nasreen','natasha','nava','navya','nayeli','neela','neeva',
    'nellie','nena','nerissa','nerys','nicolette','nika','nikita','nile','noa',
    'noemi','noriko','norina','nour','nuala','nyah','nyala','oceane','odessa',
    'odette','ofelia','olena','olympia','ondine','oona','oriana','orin',
    'ornella','ottavia','oxana','pamela','paola','paulina','pavlova',
    'penelope','petra','pia','pippa','pilar','priti','prudence','radha',
    'ramona','rania','raquel','rayne','rebekah','remi','renata','renee',
    'rianna','ria','rielle','rina','rivka','roberta','rocio',
    'rosaline','rosamund','rosaria','roselyn','roshana','rosina','roxana','royal','sable','safi','sakura','salma','samara','samira','sanaa','saniya',
    'sarahi','serafina','serena','serenity','shannon','shara','sheila','sherry',
    'sienna','sigrid','silvana','sina','sinead','siobhan','skyla','seren','soleil',
    'solene','sonia','sonora','soraya','sorina','suri','susanna','sylvie','tabitha',
    'talisa','talitha','talia','tamsin','tanis','taryn','tasha','tatiana',
    'tawny','taya','teodora','teri','thalia','theresa','tiara','tija',
    'timea','tirza','titania','tivona','tonya','tricia','trina','trudi',
    'tulip','una','ursula','vanessa','vanya','vassia','veena','verena',
    'verity','veronika','vicki','victoria','viera','virginia','viveka','wanda',
    'waverly','willow','winona','xara','xiomara','yael','yessenia','yuki','yvette',
    'yvonne','zadie','zahara','zahra','zahria','zainab','zanele','zaniya',
    'zaya','zena','zendaya','zia','zinnia','zita','ziva','zoey','zola','zora',

    // ── FOOD — FRUITS ─────────────────────────────────────────────────────────
    'apple','apricot','avocado','banana','cherry','citrus','coconut','date','grape','guava','lemon','lychee','mango','melon','nectarine',
    'orange','papaya','peach','pear','plum','pomelo','raspberry','strawberry','tangerine',
    'watermelon','blueberry','blackberry','cranberry','gooseberry','mulberry','currant',
    'grapefruit','clementine','mandarin','persimmon','quince','tamarind',

    // ── FOOD — VEGETABLES ────────────────────────────────────────────────────
    'artichoke','asparagus','aubergine','beet','broccoli','cabbage','carrot',
    'cauliflower','celery','chard','chickpea','chili','chive','courgette',
    'cucumber','eggplant','fennel','garlic','kale','leek','lentil','lettuce',
    'mushroom','okra','onion','parsley','parsnip','pepper','potato','pumpkin',
    'radish','spinach','squash','swede','tomato','turnip','yam','zucchini',

    // ── FOOD — PROTEIN & DAIRY ────────────────────────────────────────────────
    'beef','chicken','pork','venison',
    'butter','cream','cheese','yogurt','cheddar','brie','feta','gouda','mozzarella',
    'parmesan','ricotta','halloumi','bacon','sausage',

    // ── FOOD — BAKERY & GRAINS ────────────────────────────────────────────────
    'bread','cookie','croissant','donut','flour','loaf','muffin',
    'pasta','pizza','pretzel','scone','toast','tortilla','waffle','bagel',
    'brioche','focaccia','naan','rye','sourdough','pita','crumpet','pancake',

    // ── FOOD — SWEETS & DRINKS ───────────────────────────────────────────────
    'brownie','caramel','candy','chocolate','fudge','gelato','honey','jelly',
    'lolly','marshmallow','nougat','pudding','sherbet','sorbet','toffee','truffle',
    'coffee','juice','lemonade','soda','tea','water','beer','cider',
    'espresso','latte','mocha','smoothie','cocoa','cola','punch','kombucha',

    // ── BODY & HEALTH ─────────────────────────────────────────────────────────
    'stomach','thumb','toe','tongue','tooth','wrist','ankle',
    'blood','breath','gland','muscle','organ','tissue','vessel','artery',
    'fever','cough','wound','injury','fracture',
    'vitamin','mineral','protein','calorie','fiber','nutrient',

    // ── EMOTIONS ──────────────────────────────────────────────────────────────
    'anger','anxiety','courage','delight','despair','disgust',
    'doubt','dread','elation','envy','glee','gloom','grief','guilt',
    'happy','horror','longing','melancholy','misery','nostalgia',
    'panic','passion','peace','pity','pleasure','pride','relief','regret',
    'remorse','sadness','shame','shock','stress','surprise','sympathy','terror',
    'trust','wonder','worry','yearning',
    'angry','anxious','bored','brave','cheerful','confused','content',
    'curious','delighted','depressed','determined','eager','elated','embarrassed',
    'excited','frightened','grateful','grumpy','guilty','hopeful','horrified',
    'jealous','joyful','lonely','nervous','optimistic','peaceful','proud','satisfied',
    'scared','shocked','stressed','surprised','tired','worried',

    // ── COLORS ────────────────────────────────────────────────────────────────
    'green','indigo','ivory','khaki','lavender','lilac','magenta',
    'maroon','mauve','navy','ochre','olive',
    'purple','red','sapphire','scarlet',
    'silver','slate','tan','turquoise','umber','white','yellow',

    // ── NATURE & WEATHER ─────────────────────────────────────────────────────
    'autumn','blizzard','breeze','cloud','cyclone','drought',
    'earthquake','eclipse','flood','frost','hail','hurricane','lightning','monsoon','night',
    'rainbow','sleet','spring','sunrise','sunset',
    'thunder','tide','tornado','twilight','typhoon','winter',
    'asteroid','comet','galaxy','meteor','nebula','orbit','planet',
    'sun','universe','pulsar','quasar','cosmos','zenith','nadir','carbon','element','energy','force','gravity','light','matter','motion','oxygen','pressure','vacuum','velocity',

    // ── PLANTS & TREES ────────────────────────────────────────────────────────
    'dandelion','eucalyptus','fern','fir','flower','grass','hawthorn','jasmine','juniper','lotus',
    'magnolia','maple','marigold','orchid',
    'poplar','poppy','primrose','redwood','rosemary','sequoia',
    'snowdrop','spruce','sunflower','sycamore','thyme','walnut','acorn','bloom','blossom','bush','grain','petal','pollen','root','shrub','thorn','trunk',
    'bonsai','baobab','banyan','cypress','dogwood','ginkgo','hibiscus',
    'honeysuckle','hydrangea','lantana','peony','petunia','rhododendron',
    'snapdragon','verbena','wisteria',

    // ── TOYS & GAMES ──────────────────────────────────────────────────────────
    'cube','dart','doll','domino','frisbee','jigsaw','lego','marble',
    'puppet','puzzle','racket','robot','scooter','skate','slide','spinner',
    'swing','teddy','train','trumpet','yoyo','chess','checkers','poker','jenga',
    'action','badge','boss','combo','craft','dungeon','elf','fairy',
    'ghost','gnome','goblin','golem','knight','mage','ninja','orc',
    'paladin','pirate','ranger','rogue','rune','shield','sword','troll',
    'vampire','warrior','wizard','zombie','joystick','sprite',

    // ── SPORTS & ACTIVITIES ───────────────────────────────────────────────────
    'archery','boxing','climbing','cycling','diving','fencing',
    'golf','gymnastics','hiking','hockey','jogging','judo','karate','kayaking',
    'lacrosse','marathon','netball','polo','rowing','rugby','sailing','skiing',
    'soccer','softball','surfing','swimming','taekwondo','tennis','triathlon',
    'volleyball','wrestling','badminton','handball','croquet',
    'coach','field','league','match','medal','penalty',
    'referee','score','tackle','trophy','umpire',

    // ── PHOBIAS ───────────────────────────────────────────────────────────────
    'phobia','agoraphobia','claustrophobia','acrophobia','hydrophobia',
    'xenophobia','nyctophobia','trypophobia','ergophobia','nosophobia',
    'thanatophobia','necrophobia','pyrophobia','dentophobia','glossophobia',
    'emetophobia','hemophobia','mysophobia','zoophobia','ornithophobia',
    'ophidiophobia','musophobia','entomophobia','coulrophobia','brontophobia',
    'gamophobia','sociophobia','technophobia','photophobia','arachnophobia',
    'cynophobia','chronophobia','decidophobia','iatrophophobia',

    // ── SCIENCE & TECHNOLOGY ─────────────────────────────────────────────────
    'algorithm','analog','antenna','binary','blog','browser','byte','cache',
    'chip','click','code','computer','cursor','debug','domain',
    'download','email','emoji','encrypt','firewall','flash','format','frame',
    'graphics','hardware','icon','input','internet','kernel','keyboard','laptop',
    'laser','macro','memory','modem','mouse','network','output','packet','platform','plugin','power','program',
    'proxy','query','queue','radio','reboot','render','router','screen',
    'search','sensor','server','signal','smart','socket','software','source','spam','switch','sync','system','tablet','token','trace',
    'upload','virus','wifi','window','drone','nuclear',

    // ── MUSIC & ARTS ─────────────────────────────────────────────────────────
    'album','ballad','blues','chord','chorus','clef',
    'concert','duet','encore','flute','guitar','harmony','hymn',
    'jazz','lyric','melody','opera','orchestra','piano','punk','rap',
    'rhythm','rock','solo','soprano','tempo','tenor','theme','treble',
    'viola','violin','vocal','waltz','sonata','concerto','symphony',
    'abstract','acrylic','brush','canvas','cartoon','design','easel',
    'exhibit','fresco','glaze','mural','painting','palette',
    'pastel','pencil','photography','portrait','print','sculpture','sketch',
    'style','texture','watercolor','collage','mosaic','etching',

    // ── TRANSPORT ─────────────────────────────────────────────────────────────
    'airplane','ambulance','anchor','bicycle','boat','cable','canoe','cargo','cruise','cycle','ferry','flight','gondola','helicopter','jeep','kayak','locomotive','metro','monorail','motorcycle','plane','raft',
    'rocket','sailboat','shuttle','skateboard','sleigh','spacecraft',
    'speedboat','submarine','taxi','tractor','tram','tricycle','truck',
    'tugboat','van','wagon','yacht','barge','catamaran','hovercraft',

    // ── CLOTHING ──────────────────────────────────────────────────────────────
    'apron','blazer','blouse','cardigan','collar',
    'dress','fleece','frock','glove','gown','helmet','hood','jacket','jeans',
    'jumper','kimono','lace','legging','loafer','mitten','overcoat','parka','poncho','robe','sandal','sash','scarf','shirt','shorts','skirt','sleeve',
    'sneaker','sweater','tie','trench','trouser','tunic','tuxedo',
    'vest','waistcoat','bikini','denim','dungaree','leotard','tracksuit',

    // ── HOUSEHOLD ─────────────────────────────────────────────────────────────
    'armchair','basket','bath','blanket','blind','bookshelf','bowl','bucket',
    'cabinet','candle','carpet','ceiling','chair','clock','closet','couch','counter',
    'cupboard','curtain','cushion','door','drawer','dresser','dryer',
    'fireplace','floor','fridge','furnace','hammer','handle','heater','iron',
    'kettle','kitchen','ladder','laundry','mattress','microwave',
    'mirror','mop','pantry','pillow','porch','pot','radiator','shelf','shower','stair','stool','stove','table','tile',
    'toilet','towel','tub','wardrobe','washer','wrench',

    // ── SCHOOL & LEARNING ─────────────────────────────────────────────────────
    'algebra','biology','book','calculator','calendar','chemistry','class','compass',
    'concept','crayon','dictionary','diploma','eraser','formula',
    'geography','grade','graph','history','homework','journal','knowledge','language',
    'lesson','logic','math','music','notebook','paint','physics',
    'quiz','reading','report','ruler','science','semester','study','textbook',
    'theorem','theory','uniform','zoology','archaeology','philosophy',

    // ── MATERIALS ─────────────────────────────────────────────────────────────
    'fiberglass','glass','granite','hemp','jute',
    'latex','leather','linen','metal','mica','nylon','obsidian','opal',
    'paper','plastic','platinum','porcelain','polyester','quartz','resin','rubber','steel','straw','suede','titanium',
    'tungsten','velvet','vinyl','wax','wool','graphite',

    // ── JOBS & PROFESSIONS ────────────────────────────────────────────────────
    'accountant','actor','admiral','advocate','agent','architect','artist','astronaut',
    'astronomer','athlete','author','baker','banker','biologist','builder','butcher',
    'carpenter','cashier','chemist','clown','composer','conductor',
    'consultant','critic','decorator','dentist','designer','detective',
    'diplomat','director','doctor','driver','economist','editor','educator',
    'electrician','engineer','explorer','farmer','firefighter','fisherman','florist',
    'gardener','geologist','governor','guard','guide','historian','inspector',
    'journalist','judge','lawyer','librarian','linguist','locksmith','magician',
    'manager','mechanic','medic','merchant','minister','musician','navigator',
    'nurse','officer','optician','painter','pharmacist','photographer','physicist',
    'pilot','plumber','politician','postman','professor','programmer',
    'psychologist','sailor','sculptor','scientist','secretary','security',
    'soldier','surgeon','teacher','technician','therapist','translator','treasurer',
    'tutor','veterinarian','waiter','welder','writer','zoologist',

    // ── 5-LETTER WORDS ────────────────────────────────────────────────────────
    'abode','above','abuse','acute','adapt','adopt','adore','adult','ahead','alarm',
    'alive','allow','aloft','alone','alter','among','angel','annex',
    'apart','arise','array','arson','asset','attic','audio','audit','avail','avoid',
    'award','aware','basic','batch','beast','begin','bench','bible','birth','blame','bland','blank','blast','blaze','bleed','blend','bless','block','blown','boast','bonus','boost','booth',
    'bound','boxer','brand','break','bride','brief','broil','buddy','build','built','burst','buyer','carry','cause','cease','chaos','chart','cheek','cheer',
    'chief','child','choir','chunk','civic','civil','claim','clasp',
    'clean','clear','clerk','climb','cling','cloak','cloth','color','comic','count','cover',
    'crate','crazy','cross','crowd','crude','cubic','curly','daily',
    'dance','decay','decoy','defer','delay','depth','derby','dirty','disco',
    'dodge','dough','draft','drain','drama','drawn','dying',
    'early','earth','eight','elite','empty','enemy','enjoy','enter','entry','envoy',
    'equal','error','essay','ethos','evade','event','exact','exert','expel','extra',
    'fable','faint','fatal','feast','fifty','fight','final','first',
    'fixed','flank','flesh','flair','flick','flock','flown',
    'focus','forge','forte','forty','found','fraud','fresh','froze','fruit',
    'fully','funny','giant','given','gleam','glide','glint','godly',
    'grail','grand','grave','groan','grunt','guise',
    'gusto','habit','handy','havoc','heavy','hello','hence','hills','hinge','hobby','hoist','honor','human','humid','hydra','image',
    'inner','issue','itchy','kneel','knife','knock','known','kudos','label',
    'lapel','lapse','large','laugh','layer','leapt','level',
    'limit','liver','local','lofty','loose','lower','lucid',
    'magic','march','mayor','media','merit',
    'might','model','moral','motto','mount','muddy','noble','north',
    'novel','nymph','occur','onset','order','outer','oxide','ozone','patio','pause','pearl','pedal','phase',
    'pinch','pivot','plaid','plain','plait','poach','point','pouch','pound','press','price','prime','probe','proof','prose','prowl','prune',
    'pulse','pupil','purse','queen','quick','quiet','quota',
    'quote','radar','reach','realm','refer','reign','relax','relay',
    'relic','remix','repay','repel','reply','retro','revel','risky','rival','roast',
    'rocky','rough','rouse','rover','rural',
    'scene','scent','scout','sense','seize','serve','setup','seven','shave','short','siege','sixth','skill','slack','slain','slang','slant','sleep',
    'slice','slope','slump','smell','smile','smite','smoke','snack','snare',
    'sneak','snort','south','sport','spray','sprig','spunk','squad','squat','stain',
    'stake','stale','stalk','stamp','stand','stark','steal','steam',
    'steep','steer','stern','stiff','still','sting','stock','sugar','suite','super','swear','sweep','sweet','swell','swept',
    'swirl','swoop','syrup','taboo','talon','taste','teeth','tense',
    'tenth','theft','thief','thigh','thing','think','third','three',
    'throb','torso','total','touch','tough','trend','trial','tribe',
    'trite','troop','trove','truth','tweak','twice','twist','ultra','under',
    'unite','until','upper','usher','valor','value','vault','venom','video',
    'viral','visit','voice','voter','vouch','vowel','waste',
    'watch','wheat','wheel','wrath','yield','young','youth','zonal','graze','grasp','great','greed','greet','grime',
    'creep','crest','crime','crisp','crown','cruel','crush','crust','curve',
    'dream','drink','drive','drove','drown','drank',
    'flame','flare','fleet','float','floss',
    'plate','place','plaza','plead','pluck','plume',
    'share','sharp','shear','sheen','sheer','sheet','shell','shift',
    'space','spare','spark','speak','spear','speed','spell','spend','spice','spire','story','strap','stray','strip','trade','trail','trait','tramp','trick','tried',
    'verse','vigor','visor','vista','vivid','weave','wedge','weigh','weird','where','which','while','whirl',
    'wider','witch','woman','women','world','worth','would','woven','write','wrote','civet',
    'abbey','basin','bayou','bluff','canal','copse',
    'ditch','haven','islet','jetty','knoll',
    'ledge','mound','oasis','shoal',
    'aaron','abbie','aiden','alfie','angus','anton',
    'finny','floyd','haley','jamie','jenna','jenny','keira','kayla','leann','leena','leona','lewis','libby','lilly',
    'lloyd','luisa','madie','maire','mandy','marty',
    'mavis','missy','nancy','nelly','nikki',
    'niles','norma','ollie','patsy','patty',
    'roald','robby','romeo','ronda','ronin','sandy','shana','siena','sofie','sonny','sonya',
    'stacy','steve','tammy','tansy','tanya','tatum','tayla','telly','tessa',
    'tilly','timmy','winnie',

    // ── 6-LETTER+ WORDS ───────────────────────────────────────────────────────
    'absorb','accent','access','accord','across','acting','active','actual',
    'aerial','afford','afraid','agenda','agreed','alcove','almost','always','animal',
    'annual','anthem','antler','arched','ardent','around','asleep','assail',
    'atomic','atrium','attain','attend','awaken','baking',
    'battle','beacon','beauty','before','behind','belief','belong','beneath','bitter','bolder','bright','brutal','burden','button','caught','cellar','center',
    'chance','change','charge','chosen','circle','clever','client','coming',
    'comedy','common','compel','comply','confer','corner',
    'course','covert','crafty','create','credit','crisis','crutch',
    'dampen','danger','dapper','daring','darken','deadly','decide','deeply','defeat',
    'defuse','degree','depend','desire','detail','differ','divert','divine','donate','dragon','during','duster','effect','effort','embark','empire',
    'enable','engine','entire','escape','estate','evolve','exceed','except','exhale',
    'exotic','expend','expose','extend','extent','fabric','fallen','father','fathom',
    'feline','figure','finish','fiscal','flying','folded',
    'follow','formal','foster','frozen','frugal','gather','gentle','gifted',
    'glitch','golden','gossip','gothic','govern','gravel','grieve','ground',
    'hardly','hasten','helper','herald','heroic','holder','hollow','honest',
    'hustle','impact','impose','inform','insane','jockey','keeper',
    'labors','latest','launch','leader','lesion','lessen','lethal','likely','linger','listen','longer','losing','loving','lounge',
    'lumber','mentor','method','mighty','moment','mortal',
    'motive','nature','needed','nephew','nettle','normal','notice','option','origin',
    'ornate','peddle','people','permit','person','player',
    'pledge','plenty','policy','prefer','profit','prompt','proper',
    'proven','pursue','racing','radius','rattle','reason','record','reduce',
    'refuge','regime','return','reveal','rising','rotate','rugged','sacred','saddle',
    'safely','saving','scroll','secret','sector','seldom','seller','shadow','simple','single','sister','slogan','slowly','social',
    'soften','solemn','spoken','sprout','starve','steady',
    'strike','string','stroke','strong','submit','subtle','suffer',
    'supply','surely','survey','symbol','talent','tangle','target',
    'tender','thread','threat','throne','timber','timely','toward','towing',
    'travel','treaty','trendy','tribal','trying','turret','unrest',
    'useful','vanish','version','warden','warmth','weapon',
    'weaken','wealth','wither','wooden','worker','worthy',
    'abandon','absolve','account','achieve','acquire','adapter','address',
    'advance','affable','against','agitate','ailment',
    'almanac','ambling','ambient','another','approve','aptness','archway','arrange',
    'article','askance','attempt','attract','auction','auditor','average',
    'balance','banking','banquet','barrier','battery','bearing','because','bedrock',
    'believe','benefit','between','bizarre','bracket',
    'bravery','brewery','capable','captain','capture','catalog',
    'century','certain','chapter','charity','charter','circuit','climate','closest',
    'combine','comfort','command','comment','compact','compete','complex','compute',
    'concern','conduct','connect','consent','contain','contest','control',
    'convert','correct','culture','daytime','decided','declare',
    'defense','deliver','devoted','disease','display','distant','diverse',
    'dormant','dynamic','earlier','earnest','eastern','economy','edition','elegant','emotion','enhance','episode','evident','examine','example',
    'execute','exhaust','explore','extreme','faction','fantasy','fashion','fatigue',
    'feature','feeling','fiction','finally','fishing','flowing','focused',
    'foreign','forward','freedom','genuine','growing',
    'heading','healthy','hearing','helpful','horizon','hostile','however',
    'hundred','hunting','imagine','include','initial','instead','intense','involve',
    'journey','justice','kingdom','knowing','landing','learned',
    'lighter','literal','machine','magical','massage','maximum','meaning','meeting',
    'mention','minimum','miracle','missing','mixture','morning',
    'mystery','natural','nothing','obvious','offense','opinion',
    'organic','outline','outside','overall','package','perhaps','perfect',
    'picture','pattern','popular','portion','present','problem',
    'produce','project','promise','protect','provide','purpose','quality',
    'radical','realize','reality','receive','reflect','replace','require',
    'reserve','resolve','respect','restore','revenue','reverse','romance','running',
    'several','silence','somehow','someone','special','species','stellar',
    'success','surface','thought','totally','trouble','typical','unknown',
    'unusual','upgrade','victory','visible','waiting','walking',
    'warning','western','willing','winning','witness','working','writing'
  };

  bool _isValidWord(String word) {
    if (word.length < 3) return false;
    if (!word.contains(_center.toLowerCase())) return false;
    final available = [_center, ..._outer].map((l) => l.toLowerCase()).toList();
    final avail = [...available];
    for (final ch in word.toLowerCase().split('')) {
      final i = avail.indexOf(ch);
      if (i == -1) return false;
      avail.removeAt(i);
    }
    return _wordBank.contains(word.toLowerCase());
  }

  void _start(BrainDifficulty d) {
    _difficulty = d;
    _secondsLeft = switch (d) {
      BrainDifficulty.easy   => 120,
      BrainDifficulty.medium => 90,
      BrainDifficulty.hard   => 60
    };
    _found.clear();
    _selected.clear();
    _currentWord = '';
    _score = 0;
    _gameOver = false;
    _generateWheel();
    setState(() {});
    _startTimer();
  }

  static const _wheelSets = [
    ('E', ['R','G','A','T','S','N','D','I']),
    ('A', ['R','T','S','N','E','C','L','D']),
    ('I', ['N','G','R','T','S','L','P','E']),
    ('O', ['R','N','T','S','E','L','C','G']),
    ('U', ['S','T','N','G','R','L','E','P']),
    ('N', ['G','E','R','T','I','S','O','A']),
    ('S', ['T','A','N','E','R','I','O','L']),
    ('R', ['E','T','I','A','S','N','O','G']),
    ('T', ['H','E','R','A','S','I','N','O']),
    ('L', ['E','A','R','S','T','I','N','G']),
    ('C', ['A','R','E','T','S','H','O','N']),
    ('D', ['R','A','E','S','T','N','O','I']),
    ('M', ['A','R','E','S','T','N','O','I']),
    ('P', ['L','A','R','E','S','T','O','N']),
    ('G', ['R','A','E','S','T','N','O','I']),
  ];

  void _generateWheel() {
    final rng = Random();
    final ws = _wheelSets[rng.nextInt(_wheelSets.length)];
    _center = ws.$1;
    _outer = [...ws.$2]..shuffle(rng);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) { t.cancel(); _gameOver = true; }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tapLetter(int idx) {
    if (_gameOver) return;
    HapticFeedback.lightImpact();
    setState(() {
      if (_selected.contains(idx)) {
        if (_selected.last == idx) {
          _selected.removeLast();
          _currentWord = _buildWord();
        }
      } else {
        _selected.add(idx);
        _currentWord = _buildWord();
        _invalid = false;
      }
    });
  }

  String _buildWord() {
    return _selected.map((i) => i == 0 ? _center : _outer[i - 1]).join();
  }

  void _submit() {
    if (_currentWord.length < 3) return;
    final word = _currentWord.toLowerCase();
    if (_found.contains(word)) {
      setState(() { _invalid = true; });
      return;
    }
    if (_isValidWord(_currentWord)) {
      HapticFeedback.heavyImpact();
      setState(() {
        _found.add(word);
        _score += _currentWord.length;
        _selected.clear();
        _currentWord = '';
        _invalid = false;
      });
    } else {
      setState(() { _invalid = true; });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() { _invalid = false; });
      });
    }
  }

  void _clear() {
    setState(() { _selected.clear(); _currentWord = ''; _invalid = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_difficulty == null) {
      return BrainDifficultySelector(
        gameTitle: 'Word Wheel',
        description: 'Find words using the letters in the wheel.\nEvery word MUST include the center letter.\nMinimum 3 letters. Score more for longer words!\nHuge dictionary: animals, places, names, food, science & more!',
        onSelected: _start,
      );
    }
    if (!_countdownDone) {
      return BrainCountdownOverlay(onDone: () => setState(() => _countdownDone = true));
    }

    final pct = _secondsLeft / switch (_difficulty!) {
      BrainDifficulty.easy   => 120.0,
      BrainDifficulty.medium => 90.0,
      BrainDifficulty.hard   => 60.0
    };

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Column(
        children: [
          BrainGameHUD(
            score: _score,
            timerText: '${_secondsLeft}s',
            progress: pct.clamp(0.0, 1.0),
            onExit: () => Navigator.of(context).pop(),
            difficultyLabel: _difficulty!.label,
            accentColor: _accent,
          ),
          const SizedBox(height: 12),

          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            constraints: const BoxConstraints(minHeight: 52),
            decoration: BoxDecoration(
              color: _invalid
                  ? Colors.red.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _invalid ? Colors.red.withValues(alpha: 0.5)
                    : _accent.withValues(alpha: 0.2)),
            ),
            child: Center(
              child: Text(
                _currentWord.isEmpty ? 'Tap letters to form a word' : _currentWord.toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 22, fontWeight: FontWeight.w800,
                  color: _currentWord.isEmpty
                      ? Colors.white24
                      : _invalid ? Colors.red.shade300 : Colors.white,
                  letterSpacing: 4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            GestureDetector(
              onTap: _clear,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10)),
                child: Text('Clear', style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.white38)),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _submit,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_accent, _accent.withValues(alpha: 0.7)]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.3), blurRadius: 12)],
                ),
                child: Text('Submit', style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ]),
          const SizedBox(height: 16),

          Expanded(child: Center(child: _buildWheel())),

          if (_found.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _found.reversed.map((w) => Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _accent.withValues(alpha: 0.3)),
                  ),
                  child: Text(w.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w700, color: _accent)),
                )).toList(),
              ),
            ),
          const SizedBox(height: 16),

          if (_gameOver) _buildGameOver(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildWheel() {
    return LayoutBuilder(builder: (_, constraints) {
      final size = min(constraints.maxWidth, constraints.maxHeight) * 0.85;
      final center = Offset(size / 2, size / 2);
      final radius = size * 0.36;

      return SizedBox(
        width: size, height: size,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _WheelRingPainter(
                center: center, radius: radius, color: _accent.withValues(alpha: 0.1))),
            ),
            ...List.generate(8, (i) {
              final angle = (i / 8) * 2 * pi - pi / 2;
              final x = center.dx + radius * cos(angle) - 26;
              final y = center.dy + radius * sin(angle) - 26;
              final idx = i + 1;
              final isSelected = _selected.contains(idx);
              return Positioned(
                left: x, top: y,
                child: GestureDetector(
                  onTap: () => _tapLetter(idx),
                  child: _letterTile(_outer[i], isSelected, false),
                ),
              );
            }),
            Positioned(
              left: center.dx - 34, top: center.dy - 34,
              child: GestureDetector(
                onTap: () => _tapLetter(0),
                child: _letterTile(_center, _selected.contains(0), true),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _letterTile(String letter, bool selected, bool isCenter) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 52, height: 52,
      decoration: BoxDecoration(
        color: selected
            ? _accent.withValues(alpha: 0.7)
            : isCenter
                ? _accent.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.06),
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? _accent
              : isCenter ? _accent.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.12),
          width: isCenter ? 2 : 1,
        ),
        boxShadow: selected ? [BoxShadow(color: _accent.withValues(alpha: 0.5), blurRadius: 12)] : null,
      ),
      child: Center(
        child: Text(letter,
          style: GoogleFonts.poppins(
            fontSize: isCenter ? 20 : 18,
            fontWeight: FontWeight.w900,
            color: selected ? Colors.white : isCenter ? _accent : Colors.white70)),
      ),
    );
  }

  Widget _buildGameOver() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_accent, _accent.withValues(alpha: 0.7)]),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.4), blurRadius: 20)],
      ),
      child: Row(children: [
        const Text('🔠', style: TextStyle(fontSize: 26)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Time\'s Up!', style: GoogleFonts.poppins(
            fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
          Text('${_found.length} words  ·  Score: $_score',
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
        ])),
        GestureDetector(
          onTap: () { _timer?.cancel(); _start(_difficulty!); },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Text('Again', style: GoogleFonts.poppins(
              fontSize: 12, fontWeight: FontWeight.w800, color: _accent)),
          ),
        ),
      ]),
    );
  }
}

class _WheelRingPainter extends CustomPainter {
  final Offset center;
  final double radius;
  final Color color;
  const _WheelRingPainter({required this.center, required this.radius, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_WheelRingPainter old) => false;
}
