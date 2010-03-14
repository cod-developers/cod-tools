--------------------------------------------------------------------------------
--$Author$
--$Date$ 
--$Revision$
--$URL$
--------------------------------------------------------------------------------
--*
--  Table schema for the COD SQL table 'data'.
--**

DROP TABLE IF EXISTS `data`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `data` (
  `CODID` mediumint(7) unsigned NOT NULL default '0',

  `a` float unsigned NOT NULL default '0.0000',
  `siga` float unsigned,
  `b` float unsigned NOT NULL default '0.0000',
  `sigb` float unsigned,
  `c` float unsigned NOT NULL default '0.0000',
  `sigc` float unsigned,

  `alpha` float unsigned NOT NULL default '0.000',
  `sigalpha` float unsigned,
  `beta` float unsigned NOT NULL default '0.000',
  `sigbeta` float unsigned,
  `gamma` float unsigned NOT NULL default '0.000',
  `siggamma` float unsigned,

  `vol` float unsigned,
  `sigvol` float unsigned,

  `celltemp` float unsigned,
  `sigcelltemp` float unsigned,

  `diffrtemp` float unsigned,
  `sigdiffrtemp` float unsigned,

  `cellpressure` float unsigned,
  `sigcellpressure` float unsigned,

  `diffrpressure` float unsigned,
  `sigdiffrpressure` float unsigned,

  `thermalhist` varchar(255),
  `pressurehist` varchar(255),

  `nel` varchar(4) collate utf8_unicode_ci,
  `sg` varchar(32) collate utf8_unicode_ci,
  `sgHall` varchar(32) collate utf8_unicode_ci,

  `commonname` varchar(255) collate utf8_unicode_ci,
  `chemname` varchar(255) collate utf8_unicode_ci,

  `formula` varchar(255) collate utf8_unicode_ci,
  `calcformula` varchar(255) collate utf8_unicode_ci,
  `acce_code` char(6) collate utf8_unicode_ci default NULL,

  `authors` text collate utf8_unicode_ci,
  `title` text collate utf8_unicode_ci,
  `journal` varchar(255) collate utf8_unicode_ci,
  `year` smallint unsigned collate utf8_unicode_ci,
  `volume` smallint unsigned collate utf8_unicode_ci,
  `issue` tinyint unsigned collate utf8_unicode_ci,
  `firstpage` varchar(20) collate utf8_unicode_ci,
  `lastpage` varchar(20) collate utf8_unicode_ci,

  `duplicateof` mediumint(7) unsigned,
  `optimal` mediumint(7) unsigned,
  `status` enum('none', 'warnings', 'errors', 'retracted'),

  `text` text collate utf8_unicode_ci NOT NULL,

  PRIMARY KEY `CODID` (`CODID`),
  KEY `a` (`a`),
  KEY `b` (`b`),
  KEY `c` (`c`),
  KEY `alpha` (`alpha`),
  KEY `beta` (`beta`),
  KEY `gamma` (`gamma`),
  KEY `vol` (`vol`),
  KEY `sg` (`sg`),
  KEY `formula` (`formula`),
  KEY `nel` (`nel`),
  KEY `acce_code` (`acce_code`),
  FULLTEXT KEY `text` (`text`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
SET character_set_client = @saved_cs_client;
