package com.codezen.util
{
	import mx.collections.ArrayCollection;
	
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
		public static function getItemIndexByProperty(array:ArrayCollection, property:String, value:String):int{
			for (var i:int = 0; i < array.length; i++)
			{
				var obj:Object = Object(array[i])
				if (obj[property] == value)
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
			str = str.replace("&quot;", "\"");
			str = str.replace("&apos;", "'");
			str = str.replace("&amp;", "&");
			str = str.replace("&lt;", "<");
			str = str.replace("&gt;", ">");
			str = str.replace("&nbsp;", " ");
			str = str.replace("&iexcl;", "¡");
			str = str.replace("&curren;", "Û");
			str = str.replace("&cent;", "¢");
			str = str.replace("&pound;", "£");
			str = str.replace("&yen;", "´");
			str = str.replace("&brvbar;", "¦");
			str = str.replace("&sect;", "¤");
			str = str.replace("&uml;", "¬");
			str = str.replace("&copy;", "©");
			str = str.replace("&ordf;", "»");
			str = str.replace("&laquo;", "«");
			str = str.replace("&not;", "Â");
			str = str.replace("&shy;", "Ð");
			str = str.replace("&reg;", "®");
			str = str.replace("&trade;", "™");
			str = str.replace("&macr;", "ø");
			str = str.replace("&deg;", "¡");
			str = str.replace("&plusmn;", "±");
			str = str.replace("&sup2;", "Ó");
			str = str.replace("&sup3;", "Ò");
			str = str.replace("&acute;", "«");
			str = str.replace("&micro;", "µ");
			str = str.replace("&para;", "¦");
			str = str.replace("&middot;", "á");
			str = str.replace("&cedil;", "ü");
			str = str.replace("&sup1;", "Õ");
			str = str.replace("&ordm;", "¼");
			str = str.replace("&raquo;", "»");
			str = str.replace("&frac14;", "¹");
			str = str.replace("&frac12;", "¸");
			str = str.replace("&frac34;", "²");
			str = str.replace("&iquest;", "À");
			str = str.replace("&times;", "×");
			str = str.replace("&divide;", "Ö");
			str = str.replace("&Agrave;", "À");
			str = str.replace("&Aacute;", "Á");
			str = str.replace("&Acirc;", "Â");
			str = str.replace("&Atilde;", "Ã");
			str = str.replace("&Auml;", "Ä");
			str = str.replace("&Aring;", "Å");
			str = str.replace("&AElig;", "Æ");
			str = str.replace("&Ccedil;", "Ç");
			str = str.replace("&Egrave;", "È");
			str = str.replace("&Eacute;", "É");
			str = str.replace("&Ecirc;", "Ê");
			str = str.replace("&Euml;", "Ë");
			str = str.replace("&Igrave;", "Ì");
			str = str.replace("&Iacute;", "Í");
			str = str.replace("&Icirc;", "Î");
			str = str.replace("&Iuml;", "Ï");
			str = str.replace("&ETH;", "Ð");
			str = str.replace("&Ntilde;", "Ñ");
			str = str.replace("&Ograve;", "Ò");
			str = str.replace("&Oacute;", "Ó");
			str = str.replace("&Ocirc;", "Ô");
			str = str.replace("&Otilde;", "Õ");
			str = str.replace("&Ouml;", "Ö");
			str = str.replace("&Oslash;", "Ø");
			str = str.replace("&Ugrave;", "ô");
			str = str.replace("&Uacute;", "ò");
			str = str.replace("&Ucirc;", "ó");
			str = str.replace("&Uuml;", "†");
			str = str.replace("&THORN;", "Þ");
			str = str.replace("&szlig;", "§");
			str = str.replace("&agrave;", "ˆ");
			str = str.replace("&aacute;", "‡");
			str = str.replace("&acirc;", "‰");
			str = str.replace("&atilde;", "‹");
			str = str.replace("&auml;", "Š");
			str = str.replace("&aring;", "Œ");
			str = str.replace("&aelig;", "¾");
			str = str.replace("&eacute;", "Ž");
			str = str.replace("&euml;", "‘");
			str = str.replace("&igrave;", "“");
			str = str.replace("&iacute;", "’");
			str = str.replace("&icirc;", "”");
			str = str.replace("&iuml;", "•");
			str = str.replace("&eth;", "Ý");
			str = str.replace("&ntilde;", "–");
			str = str.replace("&ograve;", "˜");
			str = str.replace("&oacute;", "—");
			str = str.replace("&ocirc;", "™");
			str = str.replace("&otilde;", "›");
			str = str.replace("&ouml;", "š");
			str = str.replace("&oslash;", "¿");
			str = str.replace("&uacute;", "œ");
			str = str.replace("&ucirc;", "ž");
			str = str.replace("&uuml;", "Ÿ");
			str = str.replace("&yacute;", "à");
			str = str.replace("&thorn;", "ß");
			str = str.replace("&yuml;", "Ø");
			str = str.replace("&OElig;", "Œ");
			str = str.replace("&oelig;", "œ");
			str = str.replace("&Scaron;", "Š");
			str = str.replace("&scaron;", "š");
			str = str.replace("&Yuml;", "Ÿ");
			str = str.replace("&circ;", "ˆ");
			str = str.replace("&tilde;", "˜");
			str = str.replace("&ndash;", "–");
			str = str.replace("&mdash;", "—");
			str = str.replace("&lsquo;", "‘");
			str = str.replace("&rsquo;", "’");
			str = str.replace("&sbquo;", "‚");
			str = str.replace("&ldquo;", "“");
			str = str.replace("&rdquo;", "”");
			str = str.replace("&bdquo;", "„");
			str = str.replace("&dagger;", "†");
			str = str.replace("&Dagger;", "‡");
			str = str.replace("&hellip;", "…");
			str = str.replace("&permil;", "‰");
			str = str.replace("&lsaquo;", "‹");
			str = str.replace("&rsaquo;", "›");
			str = str.replace("&euro;", "€");
			
			return str;
			
		}
	}
}