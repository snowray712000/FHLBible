//
//  hebpar.swift
//  FHLBible
//
//  Created by littlesnow on 2024/10/7.
//

import Foundation

/*
php code
 
 /*****12 21 輸出 COBS的字型輸出到網頁用 ******/
 function hebpar($txt,$graph)
 {
   $tmp=$txt;
   $newtxt='';
   while (!(($pt=strpos($tmp,'12'))===false))
   {
         $ok1=substr($tmp,0,$pt);
         $newtxt=$newtxt.$ok1;
           $oldtmp=$tmp;
         $tmp=substr($tmp,$pt+2); //確保 12 一定在 21前面
         $pt1=strpos($tmp,'21');
         if ($pt1==0)
         {
           //echo "error in WEBhebpar $tmp <br>";
           //return;
           $tmp=$oldtmp;
           break;
         }
         $heb=substr($tmp,0,$pt1);
         if ($graph ==2)
         {
           $heb=htmlspecialchars(umscode($heb));
           $newtxt=$newtxt.'{#'.$heb.'#}';
         }
         else if ($graph ==1)
         {
           require_once('font.php');
           $heb=pfont(mscode($heb));
           $newtxt=$newtxt.$heb;
         }
         else
         {
           $heb=htmlspecialchars($heb);
           $newtxt=$newtxt.'{#'.$heb.'#}';
         }
         $tmp=substr($tmp,$pt1+2);
   }
     $newtxt=$newtxt.$tmp;
     $txt=$newtxt;
   if ($graph==0)
   {
     $txt=str_replace('{#','<font face="COBSHebrew" size="5"><nobr>',$txt);
     $txt=str_replace('#}','</nobr></font>',$txt);
   }
   else if ($graph==2)
   {
     $txt=str_replace('{#','<div style="display: inline-block;white-space: nowrap;"><font size="5"><nobr>',$txt);
     $txt=str_replace('#}','</nobr></font></div>',$txt);

     //$txt=str_replace('{#','<font size="5"><nobr>',$txt);
     //$txt=str_replace('#}','</nobr></font>',$txt);
   }
   $txt=str_replace('１２','12',$txt);
   $txt=str_replace('２１','21',$txt);
   $txt=str_replace('１','1',$txt);
   $txt=str_replace('２','2',$txt);
   return($txt);
 }
 */

// 處理 parsing 資料可能出現 1221 格式的字串
func toHebWhen1221InParsing(_ txt: String)->String{
    // 取代全型 12 21
    var txt2 = txt
    txt2 = txt2.replacingOccurrences(of: "１２", with: "12")
    txt2 = txt2.replacingOccurrences(of: "２１", with: "21")
    txt2 = txt2.replacingOccurrences(of: "１", with: "1")
    txt2 = txt2.replacingOccurrences(of: "２", with: "2")
  
    // 12(hebrew text)21 ... 12 21 是一對的，裡面夾著的就是希伯來文
    var tmp = txt2
    var newtxt = ""
    while let pt = tmp.range(of: "12"){
      let ok1 = String(tmp[..<pt.lowerBound])    
      newtxt += ok1

      tmp = String(tmp[pt.upperBound...])
      if let pt2 = tmp.range(of: "21"){
        let heb = String(tmp[..<pt2.lowerBound])
        newtxt += umscode(heb)

        tmp = String(tmp[pt2.upperBound...])  
      } else {
        // 特例， 存在 12 卻沒有 21
        newtxt += "12" // 將 原本的 12 加回去。 考慮如果 12 就是真正的內容。 12 後面的內容，即 tmp 變數，會在 while 迴圈外加回去
        break
      }

    }

    newtxt += tmp
    
    return newtxt
}
