<?php
$TP=array(
'n' => '名詞',
'v' => '動詞',
'a' => '形容詞',
'r' => '代名詞',
'rp' =>'人稱代名詞',
'rd' =>'指示代名詞',
'ri' =>'疑問代名詞',
'ai' =>'疑問形容詞',
'rr' =>'關係代名詞',
'ru' =>'不定代名詞',
'ra' =>'冠詞',
'c' => '連接詞',
'x' => '連接詞，助語字',
'i' => '感嘆詞',
'p' => '介系詞',
't' => '質詞',
'd' => '副詞',
'dr' => '關係副詞',
'drp' => '副詞加人稱代名詞',
'crp' => '連接詞加人稱代名詞',
'rre' =>'相互代名詞',
'rf' => '反身代名詞'
);
/******* 處理詞性 ******/
function de1($proid)
{
   global $TP;
   $pro=$TP[$proid] ;
   return $pro;
}
/******* 處理文法分析 ******/
function de2($proid,$pt2)
{
   /****處理parsing ******/
   $pt2=trim($pt2);
   $PC="";
   //Nouns and Pronouns (3 columns)
   if ((strcmp($proid,"n")==0)||  //名詞
       (strncmp($proid,"r",1)==0)||(strncmp($proid,'ai',2)==0)||(strcmp($proid,'drp')==0)||(strcmp($proid,'crp')==0)) //代名詞（冠詞不管了）
   {
      $c1=substr($pt2,0,1); //第一個字
      if (strcmp($c1,"n")==0) $PC=$PC."主格 ";
      elseif (strcmp($c1,"g")==0) $PC=$PC."所有格 ";
      elseif (strcmp($c1,"d")==0) $PC=$PC."間接受格 ";
      elseif (strcmp($c1,"a")==0) $PC=$PC."直接受格 ";
      elseif (strcmp($c1,"v")==0) $PC=$PC."呼格 ";
      else $PC=$PC." $c1 ";
      $c2=substr($pt2,1,1); //第二個字
      if (strcmp($c2,"s")==0) $PC=$PC."單數 ";
      elseif (strcmp($c2,"p")==0) $PC=$PC."複數 ";
      elseif (strcmp($c2,"d")==0) $PC=$PC."雙數 ";
      else $PC=$PC." $c2 ";
      $c3=substr($pt2,2,1); //第三個字
      if (strcmp($c3,"m")==0) $PC=$PC."陽性 ";
      elseif (strcmp($c3,"f")==0) $PC=$PC."陰性 ";
      elseif (strcmp($c3,"n")==0) $PC=$PC."中性 ";
      else $PC=$PC." $c3 ";
      $c4=substr($pt2,3,1); //第四個字
      if (strcmp($c4,"1")==0) $PC=$PC."第一人稱 ";
      elseif (strcmp($c4,"2")==0) $PC=$PC."第二人稱 ";
      elseif (strcmp($c4,"3")==0) $PC=$PC."第三人稱 ";
      else $PC=$PC." $c4 ";
   } //名詞與代名詞OK
   if ((strcmp($proid,"v")==0))  //動詞
   {
      //What is Ptcpl
      $ptcp=0; //先假設不是分詞第一人稱
      $c1=substr($pt2,0,1); //第一個字
      if (strcmp($c1,"p")==0) $PC=$PC."現在 ";
      elseif (strcmp($c1,"i")==0) $PC=$PC."不完成 ";
      elseif (strcmp($c1,"f")==0) $PC=$PC."第一未來 ";
      elseif (strcmp($c1,"a")==0) $PC=$PC."第一簡單過去 ";
      elseif (strcmp($c1,"b")==0) $PC=$PC."第二簡單過去 ";
      elseif (strcmp($c1,"e")==0) $PC=$PC."過去 ";
      elseif (strcmp($c1,"x")==0) $PC=$PC."第一完成 ";
      elseif (strcmp($c1,"c")==0) $PC=$PC."第二完成 ";
      elseif (strcmp($c1,"y")==0) $PC=$PC."過去完成 ";
      elseif (strcmp($c1,"d")==0) $PC=$PC."完成 ";
      elseif (strcmp($c1,"g")==0) $PC=$PC."第二未來 ";
      else $PC=$PC." $c1 ";
      $c2=substr($pt2,1,1); //第二個字
      if (strcmp($c2,"a")==0) $PC=$PC."主動 ";
      elseif (strcmp($c2,"m")==0) $PC=$PC."關身 ";
      elseif (strcmp($c2,"p")==0) $PC=$PC."被動 ";
      elseif (strcmp($c2,"n")==0) $PC=$PC."關身形主動意 ";
      elseif (strcmp($c2,"o")==0) $PC=$PC."被動形主動意 ";
      elseif (strcmp($c2,'q')==0) $PC=$PC.'關身或被動 ';
      elseif (strcmp($c2,'r')==0) $PC=$PC.'關身或被動形主動意 ';
      else $PC=$PC." $c2 ";
      $c3=substr($pt2,2,1); //第三個字
      if (strcmp($c3,"i")==0) $PC=$PC."直說語氣 ";
      elseif (strcmp($c3,"d")==0) $PC=$PC."命令語氣 ";
      elseif (strcmp($c3,"s")==0) $PC=$PC."假設語氣 ";
      elseif (strcmp($c3,"o")==0) $PC=$PC."期望語氣 ";
      elseif (strcmp($c3,"n")==0) $PC=$PC."不定詞 ";
      elseif (strcmp($c3,"p")==0)
    {
        $PC=$PC."分詞 ";
        if (strlen($pt2)==6) //六個字就是第一人稱
        {
            $ptcp=1;
            //$PC=$PC."第一人稱 ";
        }
    }
      else $PC=$PC." $c3 ";
      if ($ptcp==1)
      {
              $c4=substr($pt2,3,1); //第四個字
               if (strcmp($c4,"n")==0) $PC=$PC."主格 ";
              elseif (strcmp($c4,"g")==0) $PC=$PC."所有格 ";
              elseif (strcmp($c4,"d")==0) $PC=$PC."間接受格 ";
              elseif (strcmp($c4,"a")==0) $PC=$PC."直接受格 ";
              elseif (strcmp($c4,"v")==0) $PC=$PC."呼格 ";
              else $PC=$PC." $c4 ";
              $c5=substr($pt2,4,1); //第五個字
              if (strcmp($c5,"s")==0) $PC=$PC."單數 ";
              elseif (strcmp($c5,"p")==0) $PC=$PC."複數 ";
              elseif (strcmp($c5,"d")==0) $PC=$PC."雙數 ";
              else $PC=$PC." $c5 ";
              $c6=substr($pt2,5,1); //第六個字
              if (strcmp($c6,"m")==0) $PC=$PC."陽性 ";
              elseif (strcmp($c6,"f")==0) $PC=$PC."陰性 ";
              elseif (strcmp($c6,"n")==0) $PC=$PC."中性 ";
              else $PC=$PC." $c6 ";
      }
      else  //不是分詞
      {
          $c4=substr($pt2,3,1); //第四個字
          if (strcmp($c4,"1")==0) $PC=$PC."第一人稱 ";
          elseif (strcmp($c4,"2")==0) $PC=$PC."第二人稱 ";
          elseif (strcmp($c4,"3")==0) $PC=$PC."第三人稱 ";
          else $PC=$PC." $c4 ";
          $c5=substr($pt2,4,1); //第五個字
          if (strcmp($c5,"s")==0) $PC=$PC."單數 ";
          elseif (strcmp($c5,"p")==0) $PC=$PC."複數 ";
          elseif (strcmp($c5,"d")==0) $PC=$PC."雙數 ";
          else $PC=$PC." $c5 ";
      }
   }
   if ((strcmp($proid,"a")==0)) //形容詞
   {
      $c1=substr($pt2,0,1); //第一個字
      if (strcmp($c1,"n")==0) $PC=$PC."主格 ";
      elseif (strcmp($c1,"g")==0) $PC=$PC."所有格 ";
      elseif (strcmp($c1,"d")==0) $PC=$PC."間接受格 ";
      elseif (strcmp($c1,"a")==0) $PC=$PC."直接受格 ";
      elseif (strcmp($c1,"v")==0) $PC=$PC."呼格 ";
      else $PC=$PC." $c1 ";
      $c2=substr($pt2,1,1); //第二個字
      if (strcmp($c2,"s")==0) $PC=$PC."單數 ";
      elseif (strcmp($c2,"p")==0) $PC=$PC."複數 ";
      elseif (strcmp($c2,"d")==0) $PC=$PC."雙數 ";
      else $PC=$PC." $c2 ";
      $c3=substr($pt2,2,1); //第三個字
      if (strcmp($c3,"m")==0) $PC=$PC."陽性 ";
      elseif (strcmp($c3,"f")==0) $PC=$PC."陰性 ";
      elseif (strcmp($c3,"n")==0) $PC=$PC."中性 ";
      else $PC=$PC." $c3 ";
      $c4=substr($pt2,3,1); //第四個字
      if (strcmp($c4,"c")==0) $PC=$PC."比較級 ";
      elseif (strcmp($c4,"s")==0) $PC=$PC."最高級 ";
      else $PC=$PC." $c4 ";
   } //形容詞OK

   if (strlen(trim($PC))==0) $PC=$pt2;
   return $PC;
}
/*****[#5.3#]  輸出 §5.3  ******/
function hgarref($txt)
{
  $tmp=$txt;
 $newtxt="";
 while (!(($pt=strpos($tmp,'[#'))===false))
    {
        $ok1=substr($tmp,0,$pt);
        $newtxt=$newtxt.$ok1;
        $oldtmp=$tmp;
        $tmp=substr($tmp,$pt+2); //確保12在21之前
        $pt1=strpos($tmp,'#]');
        if ($pt1==0)
        {
           //echo "error in WEBhebpar $tmp <br>";
           //return;
           $tmp=$oldtmp;
           break;
        }
        $heb=substr($tmp,0,$pt1);
    $heb=str_replace('１','1',$heb);
        $heb=str_replace('２','2',$heb);
        $heb=str_replace('３','3',$heb);
        $heb=str_replace('４','4',$heb);
        $heb=str_replace('５','5',$heb);
        $heb=str_replace('６','6',$heb);
        $heb=str_replace('７','7',$heb);
        $heb=str_replace('８','8',$heb);
        $heb=str_replace('９','9',$heb);
        $heb=str_replace('．','.',$heb);
        //$newtxt=$newtxt.'看希伯來文讀經§'.$heb.'。';
        $newtxt=$newtxt.'§'.$heb;
        $tmp=substr($tmp,$pt1+2);
    }
    $newtxt=$newtxt.$tmp;
    $newtxt;

  return($newtxt);
}
/*****<! !> 輸出 Cross Walk的希臘文字型輸出到網頁用 ******/
function grkpar($txt,$graph)
{
  $tmp=$txt;
 $newtxt="";
 $ns=chr(34);
 while (!(($pt=strpos($tmp,"<!"))===false))
    {
        $ok1=substr($tmp,0,$pt);
        $newtxt=$newtxt.$ok1;
        $pt1=strpos($tmp,"!>");
        if ($pt1==0)
        {
           echo "error in WEB Greek parsing $tmp lost !&gt;<br>";
           return;
        }
        $grk=substr($tmp,$pt+2,$pt1-$pt-2);
        if ($graph==1)
        {
          $grk=gfont(gcode($grk,1));
          $newtxt=$newtxt.$grk;
        }
    if ($graph==2)
        {
          $grk=htmlspecialchars(gcode($grk,2));
          $newtxt=$newtxt."<!".$grk."!>";
        }

        else
        {
          $grk=htmlspecialchars(gcode($grk,0));
          $newtxt=$newtxt."<!".$grk."!>";
        }
        $tmp=substr($tmp,$pt1+2);
    }
    $newtxt=$newtxt.$tmp;
    $txt=$newtxt;
  if ($graph==0)
  {
    $txt=str_replace('<!','<font class="g1"><nobr>',$txt);
    $txt=str_replace('!>','</nobr></font>',$txt);
  }
  return($txt);
}
/*****12 21 輸出 COBS的字型輸出到網頁用 ******/
function hebpar($txt,$graph)
{
  $tmp=$txt;
 $newtxt="";
 while (!(($pt=strpos($tmp,"12"))===false))
    {
        $ok1=substr($tmp,0,$pt);
        $newtxt=$newtxt.$ok1;
    $oldtmp=$tmp;
        $tmp=substr($tmp,$pt+2); //確保 12 一定在 21前面
        $pt1=strpos($tmp,"21");
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
          $newtxt=$newtxt."{#".$heb."#}";
        }
        else if ($graph ==1)
        {
          $heb=pfont(mscode($heb));
          $newtxt=$newtxt.$heb;
        }
        else
        {
          $heb=htmlspecialchars($heb);
          $newtxt=$newtxt."{#".$heb."#}";
        }
        $tmp=substr($tmp,$pt1+2);
    }
    $newtxt=$newtxt.$tmp;
    $txt=$newtxt;
  if ($graph==0)
  {
    $txt=str_replace('{#','<font class="g2"><nobr>',$txt);
    $txt=str_replace('#}','</nobr></font>',$txt);
  }
  else if ($graph==2)
  {
    //$txt=str_replace('{#','<div style="display: inline-block;white-space: nowrap;">',$txt);
    //$txt=str_replace('#}','</div>',$txt);
    $txt=str_replace('{#','',$txt);
    $txt=str_replace('#}','',$txt);
  }
  $txt=str_replace('１２','12',$txt);
  $txt=str_replace('２１','21',$txt);
  return($txt);
}

/*****{!  !} 輸出 Hebrew Translate 的字型輸出到網頁用 ******/
function hebtranpar($txt,$graph)
{
  $tmp=$txt;
 $newtxt="";
 while (!(($pt=strpos($tmp,"{!"))===false))
    {
        $ok1=substr($tmp,0,$pt);
        $newtxt=$newtxt.$ok1;
        $pt1=strpos($tmp,"!}");
        if ($pt1==0)
        {
           echo "error in hebtranpar $tmp need !} <br>";
           return;
        }
        $heb=substr($tmp,$pt+2,$pt1-$pt-2);
    /*********
        if ($graph)
        {
          $heb=htfont($heb);
          $newtxt=$newtxt.$heb;
        }
        else
        *********/
        {
          $heb=htmlspecialchars($heb);
          $newtxt=$newtxt."{!".$heb."!}";
        }
        $tmp=substr($tmp,$pt1+2);
    }
    $newtxt=$newtxt.$tmp;
    $txt=$newtxt;
  if ($graph==0)
  {
    $txt=str_replace('{!','<font face="Hebrew Transliterate"><nobr>',$txt);
    $txt=str_replace('!}','</nobr></font>',$txt);
  }
  return($txt);
}

function umscode($txt)
{
    // 創世記1:1 實例 74 79 69 76 61 45 72 2E 42 0A 60 23 3C 72 27 61 27 68 20 74 65 61 3E 77 20 7E 49 79 3B 6D 27 56 3B 68 20 74 65 61 20 7E 79 69 68 7B 6C 2F 61 20 61 22 72 27 42
    $A=array(34, 60, 62, 63, 58,  69, 73, 79, 85, 92,125);//瘦母音
    $B=array(39, 44, 46, 47, 59, 101,105,111,117,124, 93);//胖母音
    $C=array(161,162,163,164,165,166,167,111,168,169,170);//右母音
        //70,76,102,108專配 123，瘦子音配79，胖子音配111。
    $M=array(34, 60, 62, 63, 58,  69, 73, 79, 85, 92,125,
        39, 44, 46, 47, 59, 101,105,111,117,124, 93,
        161,162,163,164,165,166,167,123,168,169,170); //母音全集
    $TS=array(33,65,71,78,87,89,90,103,110,119,121,122);//瘦子音 配 $A
    $SS=array(68,82,100,114);//畸形子音應該要配「右母音」 $C
    $FS=array(35,36,37,38,64,94,66,67,70,72,74,75,76,77,80,81,83,84,86,
        88,91,97,98,99,102,104,106,107,108,109,112,113,115,116,117,
            118,120,126); //胖子音配 $B
    $S=array(33,65,71,78,87,89,90,103,110,119,121,122,
        68,82,100,114,
        35,36,37,38,64,94,66,67,70,72,74,75,76,77,80,81,83,84,86,
            88,91,97,98,99,102,104,106,107,108,109,112,113,115,116,117,
            118,120,126,96);//子音全集
    $UTS=array('ן','וֹ','גּ','נּ','וּ','יּ','זּ','ג','נ','ו','י','ז');
    $USS=array('דּ','רּ','ד','ר');
    $UFS=array('ץ','ך','ךְ','ךּ','ף','ךָ','בּ','צּ','שּׂ','הּ','טּ','כּ','לּ','מּ','פּ','קּ'
            ,'סּ','תּ','שּׁ','ש','ע','א','ב','צ','שׂ','ה','ט','כ','ל','מ',
            'פ','ק','ס','ת','','שׁ','ח','ם');
    $US=array('ן','וֹ','גּ','נּ','וּ','יּ','זּ','ג','נ','ו','י','ז',
    'דּ','רּ','ד','ר',
    'ץ','ך','ךְ','ךּ','ף','ךָ','בּ','צּ','שּׂ','הּ','טּ','כּ','לּ','מּ','פּ','קּ'
            ,'סּ','תּ','שּׁ','ש','ע','א','ב','צ','שׂ','ה','ט','כ','ל','מ',
            'פ','ק','ס','ת','','שׁ','ח','ם','׃'); // 全部 49 個子音
    /*******
    $UA=array(mb_convert_encoding('&#1464;', 'utf-8', 'html-entities'),mb_convert_encoding('&#1462;', 'utf-8', 'html-entities'),
    mb_convert_encoding('&#1456;', 'utf-8', 'html-entities'),mb_convert_encoding('&#1457;', 'utf-8', 'html-entities'),
    mb_convert_encoding('&#1463;', 'utf-8', 'html-entities'),mb_convert_encoding('&#1461;', 'utf-8', 'html-entities'),
    mb_convert_encoding('&#1460;', 'utf-8', 'html-entities'),mb_convert_encoding('&#1465;', 'utf-8', 'html-entities'),
    mb_convert_encoding('&#1467;', 'utf-8', 'html-entities'),mb_convert_encoding('&#1459;', 'utf-8', 'html-entities'),
    mb_convert_encoding('&#1458;', 'utf-8', 'html-entities'));
    ********/
    $UA=array('ָ','ֶ','ְ','ֱ','ַ','ֵ','ִ','ֹ','ֻ','ֳ','ֲ'); // 全部 11 個母音

    $len=strlen($txt);
    $ntxt="";
    for ($pt=0;$pt<$len;$pt=$pt+1)
    {
        $now=substr($txt,$pt,1); // 取出一個字元
        $cx=ord($now); // 轉為 ascii
        if (in_array($cx,$M)) // 是否是母音
        {
            $aid=array_search($cx,$M); // 找出母音在陣列中的位置，是 0-based 還是 1 based？ php 的 array_search 是 0-based
            $aid=$aid%11;//算出這是十一個母音中的第幾個
            $ntxt=$UA[$aid].$ntxt; // 用母音的 unicode 來取代
        }
        else if(in_array($cx,$S)) // 是否是子音
        {
            $sid=array_search($cx,$S);
            $ntxt=$US[$sid].$ntxt;
        }
        else //不必處理
        {
            $ntxt=$now.$ntxt;
        }
    }
    /****結束符號******/
    return($ntxt);
}
/***********母音與子音之搭配 *************************/
function mscode($txt)
{
$A=array(34, 60, 62, 63, 58,  69, 73, 79, 85, 92,125);//瘦母音
$B=array(39, 44, 46, 47, 59, 101,105,111,117,124, 93);//胖母音
$C=array(161,162,163,164,165,166,167,111,168,169,170);//右母音
    //70,76,102,108專配 123，瘦子音配79，胖子音配111。
$M=array(34, 60, 62, 63, 58,  69, 73, 79, 85, 92,125,
     39, 44, 46, 47, 59, 101,105,111,117,124, 93,
     161,162,163,164,165,166,167,123,168,169,170); //母音全集
$TS=array(33,65,71,78,87,89,90,103,110,119,121,122);//瘦子音 配 $A
$SS=array(68,82,100,114);//畸形子音應該要配「右母音」 $C
$FS=array(35,36,37,38,64,94,66,67,70,72,74,75,76,77,80,81,83,84,86,
      88,91,97,98,99,102,104,106,107,108,109,112,113,115,116,117,
          118,120,126); //胖子音配 $B
$S=array(33,65,71,78,87,89,90,103,110,119,121,122,
     68,82,100,114,
     35,36,37,38,64,94,66,67,70,72,74,75,76,77,80,81,83,84,86,
          88,91,97,98,99,102,104,106,107,108,109,112,113,115,116,117,
          118,120,126);//子音全集
   $len=strlen($txt);
    if ($len==0) return($txt);
    $ntxt="";
    for ($pt=0;$pt<$len;$pt=$pt+1)
    {
        $now=substr($txt,$pt,1);
    $cn=ord($now);
        if ($pt<($len-1)) //look ahead不可以讓系統超過字串最後
    {
                $next=substr($txt,$pt+1,1);
        $cx=ord($next);
    }
        else
    {
                $next=""; //空字串不會在陣列中
        $cx=0;
    }
        if (in_array($cn,$M)&&in_array($cx,$S)) //母音加子音，需要處理
        {
        $aid=array_search($cn,$M);
        $aid=$aid%11;//算出這是十一個母音中的第幾個
        //看看是什麼子音
        if (in_array($cx,$FS)) //胖子音
        {
            //70,76,102,108專配 123，瘦子音配79，胖子音配111。
            //70,76,102,108 是胖子音
            if ((($cx==70)||($cx==76)||($cx==102)||($cx==108))
               && (($cn==123)||($cn==79)||($cn==111)))
               {
                $ntxt=$ntxt.chr(123).$next;
               }
            else
                       $ntxt=$ntxt.chr($B[$aid]).$next;
        }
        elseif (in_array($cx,$TS)) //瘦子音
        {
                    $ntxt=$ntxt.chr($A[$aid]).$next;
        }
        elseif (in_array($cx,$SS)) //畸形子音
        {
                    $ntxt=$ntxt.chr($C[$aid]).$next;
        }
        else
        {
             echogb("沒有 $next 這個子音");
             die('');
        }
                $pt=$pt+1;
     }
        else //不必處理
        {
                $ntxt=$ntxt.$now;
        }
    }
    $endmark=chr(96);
    /****耶路撒冷 ******************************/
    $nyes=chr(167)."~;l'vWr>y";
    $ntxt=str_replace("i~;l'vWr>y",$nyes,$ntxt);
    $nyes=chr(167)."~'l'vWryIw";
    $ntxt=str_replace("i~'l'vWryIw",$nyes,$ntxt);
    $nyes=chr(167)."~;l'vWryIw";
    $ntxt=str_replace("i~;l'vWryIw",$nyes,$ntxt);
    /******特殊的母音*******/
    $yes="(-;H)";
    $nyes="-".chr(165).chr(72);
    $ntxt=str_replace($yes,$nyes,$ntxt);
    $yes="(^;H)";
    $nyes=chr(165).chr(72);
    $ntxt=str_replace($yes,$nyes,$ntxt);
    $yes="( ;H)";
    $nyes=" ".chr(165)."H";
    $ntxt=str_replace($yes,$nyes,$ntxt);
    $yes="(\n;H)";
    $nyes="\n".chr(165)."H";
    $ntxt=str_replace($yes,$nyes,$ntxt);
    $yes="({$endmark};H)";
    $nyes="$endmark".chr(165)."H";
    $ntxt=str_replace($yes,$nyes,$ntxt);

    $yes="-;\[";
    $nyes="-".chr(165).chr(91);
    $ntxt=str_replace($yes,$nyes,$ntxt);
    $yes="^;\[";
    $nyes=chr(165).chr(91);
    $ntxt=str_replace($yes,$nyes,$ntxt);
    $yes=" ;\[";
    $nyes=" ".chr(165).chr(91);
    $ntxt=str_replace($yes,$nyes,$ntxt);
    $yes="\n;\[";
    $nyes="\n".chr(165).chr(91);
    $ntxt=str_replace($yes,$nyes,$ntxt);
    $yes="{$endmark};\[";
    $nyes="$endmark".chr(165).chr(91);
    $ntxt=str_replace($yes,$nyes,$ntxt);

    $yes="(-;x)";
    $nyes="-".chr(165)."x";
    $ntxt=str_replace($yes,$nyes,$ntxt);
    $yes="(^;x)";
    $nyes=chr(165)."x";
    $ntxt=str_replace($yes,$nyes,$ntxt);
    $yes="( ;x)";
    $nyes=" ".chr(165)."x";
    $ntxt=str_replace($yes,$nyes,$ntxt);
    $yes="(\n;x)";
    $nyes="\n".chr(165)."x";
    $ntxt=str_replace($yes,$nyes,$ntxt);
    $endmark=chr(96);
    $yes="({$endmark};x)";
    $nyes="$endmark".chr(165)."x";
    $ntxt=str_replace($yes,$nyes,$ntxt);
    /****結束符號******/
    return($ntxt);
}
function gcode($itxt,$graph)
{
 $iepuno=array(118, 59,106, 74, 39, 92,124, 91, 93, 38, 94);
 //$iepunn=array( 17, 18, 19, 20, 21, 22, 23, 28, 29, 30, 31);
 $iepunn=array(161,162,163,164,165,166,167,168,169,170,171);
 $Bpuno=array(106, 74, 92,124, 91, 93, 38, 94);
 $Bpunn=array( 36, 37, 42, 43,126, 60, 33, 64);
 //$Bpunn=array(179,180,182,183,184,185,186,187);
 $BList=array('A','I','E','U','H','O','W','R');
  $orgb=array( //must to be remove error punn
             'Aj/','Hj/','Wj/','a$/','h$/','w$/',
             'AJ/','HJ/','WJ/','a%/','h%/','w%/',
             'A]/','H]/','W]/','a</','h</','w</',
             'A^/','H^/','W^/','a@/','h@/','w@/',
             'A[/','H[/','W[/','a~/','h~/','w~/',
             'A&/','H&/','W&/','a!/','h!/','w!/',
             'A\\/','H\\/','W\\/','a*/','h*/','w*/',
             'A|/','H|/','W|/','a+/','h+/','w+/',
             'a;/','h;/','w;/',
             'A/','H/','W/','a/','h/','w/',
             "a'/","h'/","w'/","av/","hv/","wv/",
             'A&','E&','H&','I&','O&','U&','W&','a!','e!','h!','i!','o!','u!','w!',
             "a'","h'","i'","u'","w'",
             'a;','e;','h;','i;','o;','u;','w;',
             'i>','u>','i?','u?',
             'AJ','EJ','HJ','IJ','OJ','UJ','WJ','RJ','a%','e%','h%','i%','o%','u%','w%','r%',
             'A[','E[','H[','I[','O[','U[','W[','a~','e~','h~','i~','o~','u~','w~',
             'A\\','E\\','H\\','I\\','O\\','U\\','W\\','a*','e*','h*','i*','o*','u*','w*',
             'A]','E]','H]','I]','O]','U]','W]','a<','e<','h<','i<','o<','u<','w<',
             'A^','E^','H^','I^','O^','U^','W^','a@','e@','h@','i@','o@','u@','w@',
             'Aj','Ej','Hj','Ij','Oj','Wj','a$','e$','h$','i$','o$','u$','w$',
             'Aj','Ej','Hj','Ij','Oj','Wj',
             'av','ev','hv','iv','ov','uv','wv',
             'A|','E|','H|','I|','O|','U|','W|','a+','e+','h+','i+','o+','u+','w+',
             'i:','u:'
             );
 $orga=array(
             'A$/','H$/','W$/','aj/','hj/','wj/',
             'A%/','H%/','W%/','aJ/','hJ/','wJ/',
             'A</','H</','W</','a]/','h]/','w]/',
             'A@/','H@/','W@/','a^/','h^/','w^/',
             'A~/','H~/','W~/','a[/','h[/','w[/',
             'A!/','H!/','W!/','a&/','h&/','w&/',
             'A*/','H*/','W*/','a\\/','h\\/','w\\/',
             'A+/','H+/','W+/','a|/','h|/','w|/',
             'a;/','h;/','w;/',
             'A/','H/','W/','a/','h/','w/',
             'av/','hv/','wv/',"a'/","h'/","w'/",
             'A!','E!','H!','I!','O!','U!','W!','a&','e&','h&','i&','o&','u&','w&',
             "a'","h'","i'","u'","w'",
             'a;','e;','h;','i;','o;','u;','w;',
             'i>','u>','i?','u?',
             'A%','E%','H%','I%','O%','U%','W%','R%','aJ','eJ','hJ','iJ','oJ','uJ','wJ','rJ',
             'A~','E~','H~','I~','O~','U~','W~','a[','e[','h[','i[','o[','u[','w[',
             'A*','E*','H*','I*','O*','U*','W*','a\\','e\\','h\\','i\\','o\\','u\\','w\\',
             'A<','E<','H<','I<','O<','U<','W<','a]','e]','h]','i]','o]','u]','w]',
             'A@','E@','H@','I@','O@','U@','W@','a^','e^','h^','i^','o^','u^','w^',
             'A$','E$','H$','I$','O$','W$','aj','ej','hj','ij','oj','uj','wj',
             'Aj','Ej','Hj','Ij','Oj','Wj',
             'av','ev','hv','iv','ov','uv','wv',
             'A+','E+','H+','I+','O+','U+','W+','a|','e|','h|','i|','o|','u|','w|',
             'i:','u:'
             );

  $AD=array('"','#','{','}',
           'A','B','C','D','E','F','G','H','I','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','`',
           'a','b','c','d','e','f','g','h','i','k','l','m','n','o','p','q','r','s','t','u','w','x','y','z');
  $UAD=array('ς','᾽','·',';',
 'Α','Β','Χ','Δ','Ε','Φ','Γ','Η','Ι','Κ','Λ','Μ','Ν','Ο','Π','Θ','Ρ','Σ','Τ','Υ','´','Ω','Ξ','Ψ','Ζ','`',
 'α','β','χ','δ','ε','φ','γ','η','ι','κ','λ','μ','ν','ο','π','θ','ρ','σ','τ','υ','ω','ξ','ψ','ζ');
  $uorg=array(
             'ᾈ','ᾘ','ᾨ','ᾀ','ᾐ','ᾠ',
             'ᾉ','ᾙ','ᾩ','ᾁ','ᾑ','ᾡ',
             'ᾊ','ᾚ','ᾪ','ᾂ','ᾒ','ᾢ',
             'ᾋ','ᾛ','ᾫ','ᾃ','ᾓ','ᾣ',
             'ᾌ','ᾜ','ᾬ','ᾄ','ᾔ','ᾤ',
             'ᾍ','ᾝ','ᾭ','ᾅ','ᾕ','ᾥ',
             'ᾎ','ᾞ','ᾮ','ᾆ','ᾖ','ᾦ',
             'ᾏ','ᾟ','ᾯ','ᾇ','ᾗ','ᾧ',
             'ᾲ','ῂ','ῲ',
             'ᾼ','ῌ','ῼ','ᾳ','ῃ','ῳ',
             'ᾴ','ῄ','ῴ','ᾷ','ῇ','ῷ',
             'Ἅ','Ἕ','Ἥ','Ἵ','Ὅ','Ὕ','Ὥ','ἅ','ἕ','ἥ','ἵ','ὅ','ὕ','ὥ',
             'ᾶ','ῆ','ῖ','ῦ','ῶ',
             'ὰ','ὲ','ὴ','ὶ','ὸ','ὺ','ὼ',
             'ϊ','ϋ','ΐ','ΰ',
             'Ἁ','Ἑ','Ἡ','Ἱ','Ὁ','Ὑ','Ὡ','Ῥ','ἁ','ἑ','ἡ','ἱ','ὁ','ὑ','ὡ','ῥ',
             'Ἄ','Ἔ','Ἤ','Ἴ','Ὄ','὜','Ὤ','ἄ','ἔ','ἤ','ἴ','ὄ','ὔ','ὤ',
             'Ἆ','἞','Ἦ','Ἶ','὎','὞','Ὦ','ἆ','἖','ἦ','ἶ','὆','ὖ','ὦ',
             'Ἂ','Ἒ','Ἢ','Ἲ','Ὂ','὚','Ὢ','ἂ','ἒ','ἢ','ἲ','ὂ','ὒ','ὢ',
             'Ἃ','Ἓ','Ἣ','Ἳ','Ὃ','Ὓ','Ὣ','ἃ','ἓ','ἣ','ἳ','ὃ','ὓ','ὣ',
             'Ἀ','Ἐ','Ἠ','Ἰ','Ὀ',    'Ὠ','ἀ','ἐ','ἠ','ἰ','ὀ','ὐ','ὠ',
         'Ἀ','Ἐ','Ἠ','Ἰ','Ὀ',    'Ὠ',
             'ά','έ','ή','ί','ό','ύ','ώ',
             'Ἇ','἟','Ἧ','Ἷ','὏','Ὗ','Ὧ','ἇ','἗','ἧ','ἷ','὇','ὗ','ὧ',
             'ῒ','ῢ'
             );

 $len=strlen($itxt);
 if ($len==0) return($itxt);
 /***** Process line end 's' of Greek *****/
 $ns=chr(34);
 $txt=preg_replace("/s([-\r\n,.:;}{) ])/","{$ns}\\1",$itxt);
 $txt=preg_replace('/s$/',$ns,$txt);

 if ($graph==2)//unicode
 {
        $ntxt=str_replace($orga,$uorg,$txt);
        $ntxt=str_replace($orgb,$uorg,$ntxt);
        $ntxt=str_replace($AD,$UAD,$ntxt);
        return $ntxt;
 }

 /**** 處理重音與氣號 ***/
 $ntxt=substr($txt,0,1);//第一個字
 for ($pt=1;$pt<$len;$pt=$pt+1)//重音不會放在一開頭
 {
        $flag=0;
        $now=substr($txt,$pt,1);
        $key=array_search(ord($now), $iepuno);
        if ($key!==false && $graph==1)
        {
                $pre=substr($txt,$pt-1,1);
                if (strcmp($pre,'i')==0||strcmp($pre,'e')==0) //match
        {
                        $ntxt=$ntxt.chr($iepunn[$key]);
                    $flag=1;
        }
        }
         $key=array_search(ord($now), $Bpuno);
        if ($key!==false && $flag==0)
        {
                $pre=substr($txt,$pt-1,1);
                if (in_array($pre,$BList)) //match
        {
                        $ntxt=$ntxt.chr($Bpunn[$key]);
                    $flag=1;
        }
        }
        if ($flag==0) $ntxt=$ntxt.$now;
 }//for pt
 return $ntxt;
}

?>
