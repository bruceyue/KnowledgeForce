/*
 *a controller of Knowledge Force page
 */
public class KnowledgeForceController
{
    // Set controller variables
    private ApexPages.StandardSetController setController;
     
    public KnowledgeForceController()
    {
        ForceKnowledges = new KnowledgeForce__c();
        PageNum = 1;
        ShowEditBox = false;
        SortBy = 'createddate';
        SortOrder = 'descending';
        ForceUrls = new KnowledgeForce__c[] {};
    }
          
    public KnowledgeForce__c ForceKnowledges { get; set; }
    public KnowledgeForce__c [] ForceUrls { get; set; }
    public KnowledgeForce__c NewForceUrls { get; set; }
    public Boolean ShowEditBox { get; set; } // whether to show the edit box or not
    public String SearchStr { get; set; }
    public String UrlID { get; set; }
    public String SortBy { get; set; }
    public String SortOrder { get; set; } // asc or desc
    public Integer PageNum { get; set; }
    public Integer RowsPerPage { get { return 20; } }
    

    public void setupSetController() 
    {      
        String query = 'select Id, Name, Url__c, JQueryName__c, JSName__c, ApexClassName__c, Content__c, Description__c'+'createdbyid, createddate '+ 'from KnowledgeForce__c';
        if(SearchStr != null && SearchStr != '') // Are we here for a search? SOSL doesn't support wildcards at the start of a search term
        {
            query += 'where url__c LIKE \'%'+ searchStr +'%\' or '+'createdby.name LIKE \'%'+ searchStr +'%\' ';
        }
        query += 'order by ';
        string qsort;
        if(SortOrder == 'descending')
        {
            qsort = 'desc';
        }
        else
        {
            qsort = 'asc';
        }
        if(SortBy == 'createdby')
        {
            query += 'createdby.lastname '+ qsort +', createdby.firstname '+ qsort;
        }
        else
        {
            query += 'createddate '+ qsort;
        }
        this.pageNum = 1;      
        this.setController = KnowledgeForceController.createStandardSetController(query, RowsPerPage);
        this.setController.setPageNumber(1);
        ForceUrls = this.setController.getRecords();
    } 

    public Boolean HasNextPage 
    {
        get
        {
            return this.setController.getHasNext();
        }
        private set;
    }

    public Boolean HasPreviousPage
    {
        get 
        {
            return this.setController.getHasPrevious();
        }
        private set;
    }

    public String TotalPages 
    { 
        get 
        {
            if(this.setController != null)
            {
                Double doublePageNum = (Double)this.setController.getResultSize()/this.setController.getPageSize();
                Decimal numOfPages = Decimal.valueOf(doublePageNum).round(RoundingMode.CEILING);
                return numOfPages == 0 ? '1' : String.valueOf(numOfPages);
            }
            else
            {
                return '1';
            }
        } 
        private set;  
    }

    public void nextLinks() 
    {
        PageNum++;
        setController.next();
        ForceUrls = this.setController.getRecords();
    }

    public void prevLinks() 
    {
        PageNum--;
        setController.previous();
        ForceUrls = this.setController.getRecords();
    }

    public SelectOption[] getSortOptions() 
    {
        SelectOption[] options = new SelectOption[] {};
        for(String s : new string[] {'Created Date', 'Created By'})
        {
            options.add(new SelectOption(s.tolowercase().replace(' ', ''), s));
        }
        return options;
    }

    public SelectOption[] getSortOrders() 
    {
        SelectOption[] options = new SelectOption[] {};
        for(String s : new string[] { 'Ascending', 'Descending' })
        {
            options.add(new SelectOption( s.tolowercase().replace(' ', ''), s)); 
        }
        return options;
    }

    private static String convertInt(Integer num) 
    {  
        String tempVal = num == 0 ? '0' : ''; 
        Integer mod = 0;  
        Integer base = 36;
        String baseDigits = '0123456789abcdefghijklmnopqrstuvwxyz';
        while(num != 0) 
        {  
            mod = Math.Mod(num, base);  
            tempVal = baseDigits.subString(mod, mod + 1) + tempVal;  
            num /= base;  
        }  
        return tempVal;  
    } 

    public static ApexPages.StandardSetController createStandardSetController(String pQueryString, Integer pPageSize)
    {
        ApexPages.StandardSetController returnSet;
        if(pQueryString != null && pPageSize != null)
        {
            returnSet = new ApexPages.StandardSetController(Database.getQueryLocator(pQueryString));
            // we need this due to a bug in Visualforce : see 
            // http://community.salesforce.com/sforce/board/message?board.id=Visualforce&message.id=17035 
            if (returnSet.getResultSize() > 0) 
            {
                returnSet.setPageSize(pPageSize);
            }
        }
        return returnSet;
    }

    public void renderEditBox() 
    {
        ShowEditBox = true;
    }   

    public void resetURL() 
    {
        ForceKnowledges = new KnowledgeForce__c();
        ShowEditBox = false;
    }

    public void saveKnowledges()
    {
        if(ForceKnowledges.Url__c == null)
        {
            ForceKnowledges.Url__c.addError('Please enter a Url.');
        }
        /*String urlPattern = '((http|ftp|https|ftps):\\/\\/)?[\\w\\-_\\.]+\\.(([0-9]{1,3})|([a-zA-Z]{2,3})|(aero|arpa|asia|coop|info|jobs|mobi|museum|name|travel))+(:[0-9]+)?\\/?(([\w\-\.,@^%:/~\+#]*[\w\-\@^%/~\+#])((\?[a-zA-Z0-9\[\]\-\._+%\$#\=~',]*=[a-zA-Z0-9\[\]\-\._+%\$#\=~',]*)+(&[a-zA-Z0-9\[\]\-\._+%\$#\=~',]*=[a-zA-Z0-9\[\]\-\._+%\$#\=~',]*)*)?)?';
        if(!Pattern.matches(urlPattern, ForceKnowledges.Url__c)) 
        {
            ForceKnowledges.Url__c.addError('Invalid URL. Please enter again.');
            return;
        } */  
        KnowledgeForce__c [] forces = [select Id, Url__c from KnowledgeForce__c where Url__c = :ForceKnowledges.Url__c]; 
        if(!forces.IsEmpty())
        {
            ForceKnowledges.Url__c.addError('This URL is already taken. Please choose another.');
            return;
        }
        try   
        {
            upsert ForceKnowledges;
        } 
        catch(Exception e) 
        {
            Apexpages.addMessages(e);
            return;
        }
        ShowEditBox = false;
        setupSetController();
    }

    public void deleteKnowledges()
    {
        
    }

    // load a Knowledge for editting
    public void loadKnowledges()
    {
        
    }
    
    @isTest
    static void testKnowledgeForceController()
    {

    }
}