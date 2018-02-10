# 將同一頁的重複校勘數字加上 -1 , -2 編號
# 例  [01] ... [01-1]



use utf8;
use Cwd;
use strict;
use XML::DOM;

my $SourcePath = "c:/cbwork/bm/B";			# 初始目錄, 最後不用加斜線 /
my $OutputPath = "c:/temp/newbm/B";		# 目地初始目錄, 如果有需要的話. 最後不用加斜線 /

my $MakeOutputPath = 1;		# 1 : 產生對應的輸出目錄
my $IsIncludeSubDir = 1;	# 1 : 包含子目錄 0: 不含子目錄
my $FilePattern = "new.txt";	# 要找的檔案類型

my $lastpage = "";
my %notenum = ();

SearchDir($SourcePath, $OutputPath);


##########################################################################

sub SearchDir
{
	my $ThisDir = shift;		# 新的所在的目錄
	my $ThisOutputDir = shift;	# 新的的輸出目錄
	
	# print "find dir <$ThisDir>\n";
	
	if($MakeOutputPath)	# 如果需要建立對應子目錄
	{
		mkdir($ThisOutputDir) unless(-d $ThisOutputDir);
	}
	
	my $myPath = getcwd();		# 目前路徑
	chdir($ThisDir);
	my @files = glob($FilePattern);
	chdir($myPath);				# 回到目前路徑
	
	foreach my $file (sort(@files))
	{
		next if($file =~ /^\./);		# 不要 . 與 ..
		my $NewFile = $ThisDir . "/" . $file ;
		my $NewOutputFile = $ThisOutputDir . "/" . $file ;
		if (-f $NewFile)
		{
			SearchFile($NewFile , $NewOutputFile);
		}
	}
	return unless($IsIncludeSubDir);	# 若不搜尋子目錄就離開
	
	opendir (DIR, "$ThisDir");
	my @files = readdir(DIR);
	closedir(DIR);
	
	foreach my $file (sort(@files))
	{
		next if($file =~ /^\./);
		my $NewDir = $ThisDir . "/" . $file ;
		my $NewOutputDir = $ThisOutputDir . "/" . $file ; 
		if (-d $NewDir)
		{
			SearchDir($NewDir, $NewOutputDir);
		}
	}	
}

##########################################################################

sub SearchFile
{
	local $_;
	my $file = shift;
	my $outfile = shift;

	#### 要做的事

	print $file . "\n";

    run($file, $outfile);
}

##########################

# 處理單檔
sub run
{
    my $infile = shift;
    my $outfile = shift;
    local $_;

    open IN, "<:utf8", $infile;
    open OUT, ">:utf8", $outfile;
    while(<IN>)
    {
        chomp;
        $_ = run_line($_);
        print OUT $_ . "\n";
    }
    close IN;
    close OUT;
}

# 處理單行
sub run_line
{
    local $_ = shift;
    # B06n0003_p0003a01
    if(/^.*?p(.{4})/)
    {
        my $page = $1;
        if($page ne $lastpage)
        {
            # 換頁了
            %notenum = ();
            $lastpage = $page;
        }
    }
    else
    {
        return $_;
    }

    # 先移除 [[01]>]
    s/(\[\[\d\d)(\]>.*?\])/$1<heaven>$2/g;

    my $head = "";
    my $mid = "";
    while($_)
    {
        if(/^(.*?)\[(\d\d)\](.*)/)
        {
            $head .= $1;
            $mid = $2;
            $_ = $3;

            if($notenum{$mid} == 0)
            {
                $notenum{$mid} = 1;
                $head .= "[" . $mid . "]";
            }
            else
            {
                # 出現超過一次
                my $newmid = $mid . "-" . $notenum{$mid};
                $notenum{$mid} = $notenum{$mid} + 1;
                $head .= "[" . $newmid . "]";
            }
        }
        else
        {
            # 沒有校勘
            $head .= $_;
            $_ = "";
        }
    }
    $_ = $head;
    s/<heaven>//g;
    return $_;
}