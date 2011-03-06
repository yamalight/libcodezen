package com.codezen.util
{
	import flash.utils.ByteArray;
	import flash.utils.unescapeMultiByte;
	import flash.xml.XMLNode;
	import flash.xml.XMLNodeType;
	
	import mx.collections.ArrayCollection;
	import mx.utils.ObjectProxy;
	
	public final class CUtils
	{		
		/**
		 * Does the URL encoding
		 */
		public static function urlEncode(string:String):String {
			string = string.replace(/\n+/g,'\n');
			string = string.replace(/\r+/g,'\n');
			string = string.replace(/%/g, "%25");
			//string = string.replace(/$/g, "%24");
			string = string.replace(/\&/g, "%26");
			string = string.replace(/\+/g, "%2B");
			string = string.replace(/,/g, "%2C");
			string = string.replace(/\//g, "%2F");
			string = string.replace(/\:/g, "%3A");
			string = string.replace(/\;/g, "%3B");
			string = string.replace(/=/g, "%3D");
			string = string.replace(/\?/g, "%3F");
			string = string.replace(/@/g, "%40");
			string = string.replace(/#/g, "%23");
			string = string.replace(/\*/g, "");
			string = string.replace(/ /g, "+");
			
			return string;
		}
		
		public static function cleanFileName(file:String):String{
			file = file.replace(/\//g, "");
			file = file.replace(/\\/g, "");
			file = file.replace(/\?/g, "");
			file = file.replace(/\:/g, "");
			file = file.replace(/\*/g, "");
			file = file.replace(/</g, "");
			file = file.replace(/>/g, "");
			file = file.replace(/\|/g, "");
			file = file.replace(/\"/g, "");
			
			return file;
		}
		
		
		/**
		 * 
		 * @param array (ArrayCollection) - collection to search in
		 * @param property (String) - property to search for
		 * @param value (String) - value of property
		 * @return (int) index of item or -1 
		 * 
		 */
		public static function getItemIndexByProperty(array:ArrayCollection, property:String, value:String, startind:int = 0):int{
			var obj:Object;
			var i:int;
			var size:int = array.length;
			for (i = startind; i < size; i++)
			{
				obj = array[i] as Object;
				if (obj.hasOwnProperty(property) && obj[property] == value)
					return i;
			}
			return -1;
		}
		
		/**
		 * 
		 * @param html - input html text
		 * @return html without tags
		 * 
		 * Strips all tags from string
		 */
		public static function stripTags(html:String):String{
			html = html.replace(/<.+?>/gs, "");
			
			return html;
		}
		
		/**
		 * 
		 * @param rfcDateString - rfc formatted date (e.g. Fri Jan 22 07:43:12 +0000 2010)
		 * @return date - as3 format date
		 * 
		 * Converts date from string to as3 Date obj
		 */
		public static function dateFromString(rfcDateString:String):Date{
			// regexp for date
			var re:RegExp = new RegExp(/\w{3}.(\w{3}).(\d{2}).(\d{2}\:\d{2}\:\d{2}).\+\d{4}.(\d{4})/);
			// array of month
			var month:Object = {Jan:0, Feb:1, Mar:2, Apr:3, May:4, Jun:5, Jul:6, Aug:7, Sep:8, Oct:9, Nov:10, Dec:11};
			// res array
			var res:Array = [];
			// date object
			var date:Date = new Date();
			// time temp var
			var monthStr:String;
			var time:String;
			// Mon Feb 01 13:14:38 +0000 2010	
			res = re.exec(rfcDateString);
			time = res[3];
			monthStr = res[1];
			// set date
			date.setFullYear(res[4],month[monthStr],res[2]);
			date.setHours(time.split(":")[0]);
			date.setMinutes(time.split(":")[1]);
			date.setSeconds(time.split(":")[2]);
			
			// clean
			re = null;
			month = null;
			res = null;
			monthStr = null;
			time = null;
			
			return date;
		}
		
		/**
		 * Removes whitespaces from start of string
		 * 
		 * @param string
		 * @return string with no whitespaces at start 
		 * 
		 */
		public static function TrimStart(string:String):String{
			if (string.charAt(0)==" " && string.length>0){
				return TrimStart(string.slice(1));
			}else{
				return string;
			}
		}
		
		/**
		 * Removes whitespaces from end of string
		 * 
		 * @param string
		 * @return string with no whitespaces at end 
		 * 
		 */
		public static function TrimEnd(string:String):String{
			if (string.charAt(string.length-1)==" " && string.length>0){
				return TrimEnd(string.slice(0,string.length-1));
			}else{
				return string;
			}
		}
		
		/**
		 * Removes whitespaces from start and end of string
		 * 
		 * @param string
		 * @return string with no whitespaces at start and end 
		 * 
		 */
		public static function Trim(string:String):String{
			string = TrimStart(string);
			string = TrimEnd(string);
			return string;
		}
		
		/**
		 * Converts all HTML entities in string to normal text chars 
		 * @param str
		 * @return str with entities changed to symbols
		 * 
		 */
		public static function convertHTMLEntities(str:String):String {
			if( str == null || str.length < 1) return '';
			
			str = str.replace(/&quot;/gs, "\"");
			str = str.replace(/&apos;/gs, "'");
			str = str.replace(/&amp;/gs, "&");
			str = str.replace(/&lt;/gs, "<");
			str = str.replace(/&gt;/gs, ">");
			str = str.replace(/&nbsp;/gs, " ");
			str = str.replace(/&iexcl;/gs, "¡");
			str = str.replace(/&curren;/gs, "Û");
			str = str.replace(/&cent;/gs, "¢");
			str = str.replace(/&pound;/gs, "£");
			str = str.replace(/&yen;/gs, "´");
			str = str.replace(/&brvbar;/gs, "¦");
			str = str.replace(/&sect;/gs, "¤");
			str = str.replace(/&uml;/gs, "¬");
			str = str.replace(/&copy;/gs, "©");
			str = str.replace(/&ordf;/gs, "»");
			str = str.replace(/&laquo;/gs, "«");
			str = str.replace(/&not;/gs, "Â");
			str = str.replace(/&shy;/gs, "Ð");
			str = str.replace(/&reg;/gs, "®");
			str = str.replace(/&trade;/gs, "™");
			str = str.replace(/&macr;/gs, "ø");
			str = str.replace(/&deg;/gs, "¡");
			str = str.replace(/&plusmn;/gs, "±");
			str = str.replace(/&sup2;/gs, "Ó");
			str = str.replace(/&sup3;/gs, "Ò");
			str = str.replace(/&acute;/gs, "«");
			str = str.replace(/&micro;/gs, "µ");
			str = str.replace(/&para;/gs, "¦");
			str = str.replace(/&middot;/gs, "á");
			str = str.replace(/&cedil;/gs, "ü");
			str = str.replace(/&sup1;/gs, "Õ");
			str = str.replace(/&ordm;/gs, "¼");
			str = str.replace(/&raquo;/gs, "»");
			str = str.replace(/&frac14;/gs, "¹");
			str = str.replace(/&frac12;/gs, "¸");
			str = str.replace(/&frac34;/gs, "²");
			str = str.replace(/&iquest;/gs, "À");
			str = str.replace(/&times;/gs, "×");
			str = str.replace(/&divide;/gs, "Ö");
			str = str.replace(/&Agrave;/gs, "À");
			str = str.replace(/&Aacute;/gs, "Á");
			str = str.replace(/&Acirc;/gs, "Â");
			str = str.replace(/&Atilde;/gs, "Ã");
			str = str.replace(/&Auml;/gs, "Ä");
			str = str.replace(/&Aring;/gs, "Å");
			str = str.replace(/&AElig;/gs, "Æ");
			str = str.replace(/&Ccedil;/gs, "Ç");
			str = str.replace(/&Egrave;/gs, "È");
			str = str.replace(/&Eacute;/gs, "É");
			str = str.replace(/&Ecirc;/gs, "Ê");
			str = str.replace(/&Euml;/gs, "Ë");
			str = str.replace(/&Igrave;/gs, "Ì");
			str = str.replace(/&Iacute;/gs, "Í");
			str = str.replace(/&Icirc;/gs, "Î");
			str = str.replace(/&Iuml;/gs, "Ï");
			str = str.replace(/&ETH;/gs, "Ð");
			str = str.replace(/&Ntilde;/gs, "Ñ");
			str = str.replace(/&Ograve;/gs, "Ò");
			str = str.replace(/&Oacute;/gs, "Ó");
			str = str.replace(/&Ocirc;/gs, "Ô");
			str = str.replace(/&Otilde;/gs, "Õ");
			str = str.replace(/&Ouml;/gs, "Ö");
			str = str.replace(/&Oslash;/gs, "Ø");
			str = str.replace(/&Ugrave;/gs, "ô");
			str = str.replace(/&Uacute;/gs, "ò");
			str = str.replace(/&Ucirc;/gs, "ó");
			str = str.replace(/&Uuml;/gs, "†");
			str = str.replace(/&THORN;/gs, "Þ");
			str = str.replace(/&szlig;/gs, "§");
			str = str.replace(/&agrave;/gs, "ˆ");
			str = str.replace(/&aacute;/gs, "‡");
			str = str.replace(/&acirc;/gs, "‰");
			str = str.replace(/&atilde;/gs, "‹");
			str = str.replace(/&auml;/gs, "Š");
			str = str.replace(/&aring;/gs, "Œ");
			str = str.replace(/&aelig;/gs, "¾");
			str = str.replace(/&eacute;/gs, "Ž");
			str = str.replace(/&euml;/gs, "‘");
			str = str.replace(/&igrave;/gs, "“");
			str = str.replace(/&iacute;/gs, "’");
			str = str.replace(/&icirc;/gs, "”");
			str = str.replace(/&iuml;/gs, "•");
			str = str.replace(/&eth;/gs, "Ý");
			str = str.replace(/&ntilde;/gs, "–");
			str = str.replace(/&ograve;/gs, "˜");
			str = str.replace(/&oacute;/gs, "—");
			str = str.replace(/&ocirc;/gs, "™");
			str = str.replace(/&otilde;/gs, "›");
			str = str.replace(/&ouml;/gs, "š");
			str = str.replace(/&oslash;/gs, "¿");
			str = str.replace(/&uacute;/gs, "œ");
			str = str.replace(/&ucirc;/gs, "ž");
			str = str.replace(/&uuml;/gs, "Ÿ");
			str = str.replace(/&yacute;/gs, "à");
			str = str.replace(/&thorn;/gs, "ß");
			str = str.replace(/&yuml;/gs, "Ø");
			str = str.replace(/&OElig;/gs, "Œ");
			str = str.replace(/&oelig;/gs, "œ");
			str = str.replace(/&Scaron;/gs, "Š");
			str = str.replace(/&scaron;/gs, "š");
			str = str.replace(/&Yuml;/gs, "Ÿ");
			str = str.replace(/&circ;/gs, "ˆ");
			str = str.replace(/&tilde;/gs, "˜");
			str = str.replace(/&ndash;/gs, "–");
			str = str.replace(/&mdash;/gs, "—");
			str = str.replace(/&lsquo;/gs, "‘");
			str = str.replace(/&rsquo;/gs, "’");
			str = str.replace(/&sbquo;/gs, "‚");
			str = str.replace(/&ldquo;/gs, "“");
			str = str.replace(/&rdquo;/gs, "”");
			str = str.replace(/&bdquo;/gs, "„");
			str = str.replace(/&dagger;/gs, "†");
			str = str.replace(/&Dagger;/gs, "‡");
			str = str.replace(/&hellip;/gs, "…");
			str = str.replace(/&permil;/gs, "‰");
			str = str.replace(/&lsaquo;/gs, "‹");
			str = str.replace(/&rsaquo;/gs, "›");
			str = str.replace(/&euro;/gs, "€");
			str = str.replace(/&#215;/gs, "×");
			
			return str;
			
		}
		
		public static function htmlEscape(str:String):String
		{
			return XML( new XMLNode( XMLNodeType.TEXT_NODE, str ) ).toXMLString();
		}
		
		/**
		 * Prepares Vkontakte Video title 
		 * @param title
		 * 
		 */
		public static function prepareVkVideoTitle(title:String):String{
			return Trim( convertHTMLEntities(unescapeMultiByte(title)).replace(/\+/gs, " ").replace(/\s\s+/gs, " ") );
		}
		
		/**
		 *	Levenshtein distance (editDistance) is a measure of the similarity between two strings,
		 *	The distance is the number of deletions, insertions, or substitutions required to
		 *	transform p_source into p_target.
		 *
		 *	@param p_source The source string.
		 *
		 *	@param p_target The target string.
		 *
		 *	@returns uint
		 *
		 * 	@langversion ActionScript 3.0
		 *	@playerversion Flash 9.0
		 *	@tiptext
		 * 
		 *  from String Utilities class by Ryan Matsikas
		 */
		public static function editDistance(p_source:String, p_target:String):uint {
			var i:uint;
			
			if (p_source == null) { p_source = ''; }
			if (p_target == null) { p_target = ''; }
			
			if (p_source == p_target) { return 0; }
			
			var d:Array = new Array();
			var cost:uint;
			var n:uint = p_source.length;
			var m:uint = p_target.length;
			var j:uint;
			
			if (n == 0) { return m; }
			if (m == 0) { return n; }
			
			for (i=0; i<=n; i++) { d[i] = new Array(); }
			for (i=0; i<=n; i++) { d[i][0] = i; }
			for (j=0; j<=m; j++) { d[0][j] = j; }
			
			for (i=1; i<=n; i++) {
				
				var s_i:String = p_source.charAt(i-1);
				for (j=1; j<=m; j++) {
					
					var t_j:String = p_target.charAt(j-1);
					
					if (s_i == t_j) { cost = 0; }
					else { cost = 1; }
					
					d[i][j] = _minimum(d[i-1][j]+1, d[i][j-1]+1, d[i-1][j-1]+cost);
				}
			}
			return d[n][m];
		}
		
		/**
		 * Trims string 
		 * @param p_string
		 * @return 
		 * 
		 */
		public static function trim(p_string:String):String {
			if (p_string == null) return '';
			return p_string.replace(/^\s+|\s+$/g, '');
		}
		
		/**
		 *	Determines the percentage of similiarity, based on editDistance
		 *
		 *	@param source The source string.
		 *	@param target The target string.
		 *
		 *	@returns Number
		 */
		public static function compareStrings(source:String, target:String):Number {
			if( source == null || target == null ) return -1;
			var ed:uint = editDistance(source, target);
			var maxLen:uint = Math.max(source.length, target.length);
			if (maxLen == 0) { return 100; }
			else { return (1 - ed/maxLen) * 100; }
		}
		
		private static function _minimum(a:uint, b:uint, c:uint):uint {
			return Math.min(a, Math.min(b, Math.min(c,a)));
		}
	}
}