<?php
require('enable_ajax.php');
require('../new/config.php');
require('dbconfig.php');
require('lang.php');
require('../new/code.php');
require('../new/hmfont.php'); //要處理羅馬拼音

// ' 變為 '' ， 是為了避免 SQL Injection
$chineses=str_replace("'","''",trim($_REQUEST['engs']));
$qstr=str_replace("'","''",trim($_REQUEST['qstr']));
$version=str_replace("'","''",trim($_REQUEST['version']));

// 預設值 (像有 3:21，它就沒有chineses，或寫 21，就沒有 chap)
if (strlen($version)==0) $version='nstrunv';
if ($chap<=0) $chap=1;
if (strlen($chineses)==0) $chineses='羅';

// 簡體中文，1
$GBCODE=(int) $_REQUEST['gb'];

// 是否要顯示 strong number 0 或 1
$strong=(int)$_REQUEST['strong'];

require('strong.php');

// gbbook 在 lang.php 中，它就是將各種表示書卷的英文，寫成中文(繁體)
// iconv 是 php 內建的函式, python 可用 chineses.encode('utf-8').decode('gb2312')
$tmp=gbbook($chineses);
if (strcmp($tmp,$chineses)==0 && $GBCODE==1)
    // 若是英文，就一定不成立。
    // 若是繁中，就會成立 第一條件。
    // TODO: 待確認，為何 php 有建議的 iconv，但卻還要另外寫 gb2bga.php 或 bg2gba.php ?
    // 已確認，原本是用 iconv，但轉換不好，所以後來大陸弟兄提供了 gb2bga.php 或 bg2gba.php。
    $chineses=gbbook(iconv('utf-8','gb2312',$chineses));
elseif ($GBCODE==1) $chineses=$tmp;

$db_conn=db_connect("dbname=$DBNAME");
db_set_encoding($db_conn,'utf-8');

// 先以 ; 分割
$stok=explode(';',$qstr);

// 開始回傳 json 的前面
echo '{'."\n";

$outmsg='';
$ocnt=0;
for ($i=0;$i<count($stok);$i++)
{
    // 可以看出，幾個 ; ，就會 select 幾次。

    // 從下文看 BLIMIT ，就是決定 chap 與 sec 條件的，我們看不到 where chap sec 的條件，因為這裡用 chap * 10000 + sec 這個數字來比較，也就是它假設不會有 chap 超過 1000 個 sec，這也是合理的假設。又因為，若換書卷，以 ; 分割，所以也不會出現跨書卷的問題。
    $BLIMIT='';

    // 消除多餘的空白
    $stok[$i]=trim($stok[$i]);

    // 無益義的，例如 qstr = Ro5:1;;Mt 1。
    if (strlen($stok[$i])==0) continue;

    // nowtok 就是其中一項，例如 Ro5:1
    $nowtok=$stok[$i];
    
    if (!is_numeric(substr($nowtok,0,1)))
        // 條件：第一個字元 不是數字
        // 這 chineses 是 query string ，表示為原本書卷預設值。
        // 例如 Ro5:1，若是 5:1 而已，就要用預設書卷(或是前一次出現的書卷，例如 Ro5:1;7:2)
        $chineses='';
    else if ($GBCODE==1)$chineses=$oldchineses;
    
    // 將文字略過，例如 `Ro 5:1`，變為` 5:1`
    while (!is_numeric(substr($nowtok,0,1)))
    {
       $chineses=$chineses.substr($nowtok,0,1);
       $nowtok=substr($nowtok,1);
    }

    $chineses=trim($chineses);
    // 供下次使用
    $oldchineses=$chineses;

    // 英文轉為簡體
    $tmp=gbbook($chineses);
    if (strcmp($tmp,$chineses)==0 && $GBCODE==1)
        $chineses=gbbook(iconv('utf-8','gb2312',$chineses));
    else $chineses=$tmp;

    // 各種情境 (5:1-3,5,7) (5:1-7:3) (2) ... 2 是整章，不是第2節 (規格中，沒有第2節)
    // 這裡要產生 BLIMIT 條件字串，它是由 chap sec 組成
    $pt=strpos($nowtok,':');
    $pcnt=substr_count($nowtok,':');
    $part4=0;
    if ($pcnt==2 && $pt!==false)
    {
        // 5:1-7:3 這種情境
        $beitem=explode('-',$nowtok);
        $barr=explode(':',$beitem[0]);
        $earr=explode(':',$beitem[1]);
        $bchap=(int)$barr[0];
        $bsec=(int)$barr[1];
        $echap=(int)$earr[0];
        $esec=(int)$earr[1];
        $bsco=$bchap*1000+$bsec;
        $esco=$echap*1000+$esec;
        $BLIMIT=$BLIMIT."or ( bible.chap*1000+bible.sec >= $bsco and bible.chap*1000+bible.sec <= $esco )";
	    $part4=1;
    }
    else if ($pt!==false)
    {
        // 5:1 或 5:1-3,5,7 或 1:1,4-6,7,8 這種情境
        $chap=(int)$nowtok;
        $secstr=substr($nowtok,$pt+1); # 留下 1 或 1-3,5,7 或 1,4-6,7,8
    }
    else
    {
        // 沒有 `:`，例如 `約二` or `約 5` or `約`
        // 其實信望愛沒有支援，只寫 節。當只有數字時，就是整章，若多個數字，例如 1-3,5,7，應該是要多節，但原程式 qsb.php 沒支援，所以這裡也沒支援。
        $chap=(int)$nowtok;
        $secstr='';
    }

    if ($part4==0)
    {
        // 第二種情況，第三種情況
        $BLIMIT='';
        if (strlen($secstr)>0)  //# mt 1:1-3,4,8
        {
            // 第二種情況
            if (strstr($secstr,','))
            {
                $tok = strtok ($secstr,',');
                $SLIMIT='';
                while (!($tok === FALSE)) // #mt 1:1,2,5,7
                {
                    if (strstr($tok,'-')) // #mt 1:1-3,6,10
                    {
                        $SLIMIT=$SLIMIT.parsed($tok);
                    }
                    else
                    {
                        $tok=(int) $tok;
                        $SLIMIT=$SLIMIT."or bible.sec=$tok ";
                    }
                    $tok = strtok (',');
                }
                $SLIMIT=substr($SLIMIT,2); //拿掉前面兩個字元 or
                $BLIMIT=$BLIMIT." or ( bible.chap=$chap and ( $SLIMIT ))";
            }
            elseif (strstr($secstr,"-"))
            {
                // 2:2-8 這種
                $tok = (int) strtok ($secstr,'-');
                $BLIMIT="or (bible.chap=$chap and (bible.sec>=$tok and ";
                $tok = (int) strtok ('-');
                $BLIMIT=$BLIMIT." bible.sec<=$tok))";
            }
            elseif ($secstr=='0')
            {
                $BLIMIT=$BLIMIT." or ( bible.chap=$chap )";
            }
            else 
            {
                // 2:1 這種
                $BLIMIT=$BLIMIT."or ( bible.chap=$chap and bible.sec=$secstr )";
            }
        } //sec >0
        else
        {
            // 整章
            $BLIMIT=$BLIMIT."or ( bible.chap=$chap )";
        }
    } //part4==0

    if (substr($chineses,0,1)=='#')
    {
        $chineses=substr($chineses,1);
    }

    $SQL="select main.chineses,bible.engs,bible.chap,bible.sec,bible.txt from $version as bible,main where bible.engs=main.engs and (main.chineses='${chineses}' or main.engs='${chineses}') and ( false  $BLIMIT ) order by bible.engs,bible.chap,bible.sec";

    $result=db_exec($db_conn,$SQL);
    if (!$result)
    {
    echo '"status":"Fail:'.$SQL.'"'."\n";
    die( '}');
    }
    $numrow=db_NumRows($result);
    $ocnt=$ocnt+$numrow;
    for ($ii=0;$ii<$numrow;$ii=$ii+1)
	{
		$ARAW=db_fetch_row($result,$ii);
		for ($j=0;$j<count($ARAW);$j++) $ARAW[$j]=trim($ARAW[$j]);
        
        if ($strong==0) $ARAW[4]=procstrong(0,$ARAW[4]);
		
        if ($proclist[$version]==3) # 羅馬拚音
		{
			$ARAW[4]=to_utf8($ARAW[4],0);
		}
        else if ($proclist[$version]==2) # 希伯來文
        {
            $ARAW[4]=umscode($ARAW[4]);
            # ms: Masoretic Text (瑪索拉文本)
            # ums: unicode ms
        }    
        else if ($proclist[$version]==1) # 希臘文
        {
            $ARAW[4]=gcode($ARAW[4],2);
            # gcode 定義在 code.php，是希臘文相關的處理
            # 參數 2 是 unicode 就回傳
        }
        else if ($version=='lxx') # 七十士譯本
        {
            $ARAW[4]=gcode($ARAW[4],2);
        }

		$outmsg=$outmsg.("{\"chineses\":".json_encode(trangb($ARAW[0])).",\"engs\":\"${ARAW[1]}\",\"chap\":${ARAW[2]},\"sec\":${ARAW[3]},\"bible_text\":".json_encode(trangb($ARAW[4]))."},");
	}
}

echo '"status":"success",'."\n";
echo '"record_count":'.$ocnt.','."\n";
$proc_lang=(int)$proclist[$version]; 
echo '"proc":'.$proc_lang.','."\n";
$outmsg=substr($outmsg,0,strlen($outmsg)-1);
$outmsg=str_replace("\r\n",'\n',$outmsg);
$outmsg=str_replace("\n",'\n',$outmsg);
echo('"record":['.$outmsg.']}');
	
function parsed($tok)
{
      $LIMIT='';
      $gtok=explode('-',$tok);
      //$gtok = strtok ($tok,"-");
      $gtok[0]=(int) $gtok[0];
      $gtok[1]=(int) $gtok[1];
      $LIMIT="or (bible.sec>=$gtok[0] and bible.sec<=$gtok[1]) ";
      return($LIMIT);
}

?>