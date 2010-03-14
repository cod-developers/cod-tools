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
  `file` mediumint(7) unsigned NOT NULL default '0',
  `a` float unsigned NOT NULL default '0.0000',
  `b` float unsigned NOT NULL default '0.0000',
  `c` float unsigned NOT NULL default '0.0000',
  `alpha` float unsigned NOT NULL default '0.000',
  `beta` float unsigned NOT NULL default '0.000',
  `gamma` float unsigned NOT NULL default '0.000',
  `vol` float unsigned NOT NULL default '0.00',
  `celltemp` float unsigned,
  `diffrtemp` float unsigned,
  `cellpressure` float unsigned,
  `diffrpressure` float unsigned,

  `nel` varchar(4) collate utf8_unicode_ci,
  `sg` varchar(32) collate utf8_unicode_ci,

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

  `text` text collate utf8_unicode_ci NOT NULL,

  PRIMARY KEY `file` (`file`),
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
