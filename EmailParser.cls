global class EmailParser implements Messaging.InboundEmailHandler {

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email,
                                                       Messaging.InboundEnvelope env){
    
        // Create an InboundEmailResult object for returning the result of the Apex Email Service
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        
        // Add the email plain text into the local variable
        // This will be done regardless on who the email is from
        String myPlainText = email.plainTextBody;

        //make a copy of the plain text in case we have to reference a 'fresh' copy of the email
        String copyOfPlainText = myPlainText.substring(0, myPlainText.length());

        // Check and see if the plain text contains the word "Arlo", "Netgear", and the address of the company.
        // If this is true then there is a high probability that the email is from Arlo and it will be
        // parsed in a way to reflect that.  It is also likely that the email was a motion notification.
        if ((myPlainText.contains('Arlo')) && (myPlainText.contains('NETGEAR')) && (myPlainText.contains('motion')) && (myPlainText.contains('NETGEAR Inc. 350 E. Plumeria Drive San Jose'))) {   
            //Following the template of the email from Arlo, split the plain text accordingly

            //the name of the contact
            String nameOfContact = myPlainText.substringBefore(',');  

            //the first name of the contact.  Arlo only sends us the first name in the email so we will have to work with it.
            String firstNameOfContact =  myPlainText.substring(3, nameOfContact.length()); 

            //the name of the device that detected the motion
            String tempNameOfAsset1 = copyOfPlainText.substringAfter(':');
            
            //remove any newline statements from the string;  there are normally 2 of them.
            tempNameOfAsset1 = tempNameOfAsset1.replace('\n', '');
            tempNameOfAsset1 = tempNameOfAsset1.replace('\n', '');

            //further refine the name of the device
            String tempNameOfAsset2 = tempNameOfAsset1.substring(0, 40);

            //the final name of the device
            String finalNameOfAsset = tempNameOfAsset2.substringBetween('', ' at ');
            

            //make a new Contact
            Contact caseContact;
            
            //code to find an existing contact
            try{
                System.debug('TRY');
                System.debug('firstNameOfContact=' + firstNameOfContact);

                //SOQL query to find the first name of the contact already in the database.  It will only return the first result.
                caseContact = [SELECT Id FROM CONTACT WHERE Contact.FirstName = :firstNameOfContact LIMIT 1];
                
            } catch(Exception ex) {
                System.debug('CATCH');

                //if we didn't find it with the SOQL query then we want to make a new contact.
                
                Contact newCaseContact = new Contact();

                //set the first name of the contact
                newCaseContact.FirstName = firstNameOfContact;  

                //the last name isn't given in the email and it's required to create a new contact.
                //we will set it to a static string, "CHANGEME", which instructs the case management operator to change and fill in the last name of the contact
                newCaseContact.LastName = 'CHANGEME';
                
                //insert the new contact into the Contact database
                insert newCaseContact; 
                    
                //create a new case object
                Case emailToCase = new Case();

                //fill in the subject line of the case
                emailToCase.Subject = finalNameOfAsset + ', Camera has detected motion!';

                //copy all of the information from the email into the description
                emailToCase.Description = myPlainText;

                //fill in the origin of the case
                emailToCase.Origin = 'Email';

                //link the new contact with the this new case object
                emailToCase.ContactId = newCaseContact.id;

                //set the priority to low as default because it was only motion on a camera
                emailToCase.Priority = 'Low';
    
                //insert the case into the database
                insert emailToCase;
                
                //set the success to true because we were able to complete the email to case
                result.success = true;
                
                //return the result and terminate the program
                return result;
                
            }        
            
            //otherwise, the contact already exists, simply pull up their information and insert the new case

            //create a new case object
            Case emailToCase = new Case();

            //fill in the subject line of the new case
            emailToCase.Subject = finalNameOfAsset + ', Camera has detected motion!';

            //copy all of the information from the email into the description
            emailToCase.Description = myPlainText;

            //fill in the origin of the case
            emailToCase.Origin = 'Email';

            //link the existing contact with the new case
            emailToCase.ContactId = caseContact.id;

            //set the priority to low as default because it was only motion on a camera
            emailToCase.Priority = 'Low';
            
            //insert the case in to the database
            insert emailToCase;

        //check and see if the email contains the word "Lyric", then with high probability the email is from Lyric
        } else if ((myPlainText.contains('Lyric')) && myPlainText.contains('Honeywell') && myPlainText.contains('Water Leak') && myPlainText.contains('Detected')) {

         //Do some hard coded parsing to pull the first name and last name out of the email
         //Check it against the existing contacts to see if the contact exists, otherwise make a new one.
         
            //Find the complete name of the contact
            String nameOfContact1 = myPlainText.substringBetween('The following user have access to', '.');  
            System.debug('nameOfContact1=' + nameOfContact1);
            String nameOfContact2 = nameOfContact1.substringAfter(':');
            System.debug('nameOfContact2=' + nameOfContact2);
            
            //Find the last name of the contact
            String lastNameOfContact1 = nameOfContact2.trim();
            System.debug('lastNameOfContact1=' + lastNameOfContact1);
            String lastNameOfContact2 = lastNameOfContact1.substringAfter(' ');
            System.debug('lastNameOfContact2=' + lastNameOfContact2);
            
            //Find the first name of the contact
            String firstNameOfContact1 =  nameOfContact2.substringBeforeLast(' ');
            System.debug('firstNameOfContact1=' + firstNameOfContact1);
            String firstNameOfContact2 =  firstNameOfContact1.trim();
            System.debug('firstNameOfContact2=' + firstNameOfContact2);
            
            //Find the name of the device
            String nameOfLocation1 = myPlainText;
            System.debug('nameOfLocation1=' + nameOfLocation1);
            String nameOfLocation2 = nameOfLocation1.substringBetween('have access to', 'location:').trim();
            System.debug('nameOfLocation2=' + nameOfLocation2);
            
            
            //create a new contact object
            Contact caseContact2;
            
            //code to find an existing contact
            try{
                System.debug('TRY');
                System.debug(firstNameOfContact2);
                System.debug(lastNameOfContact2);

                //SOQL query to find an existing contact in the database with the first and last name specified in the email
                caseContact2 = [SELECT Id FROM CONTACT WHERE Contact.FirstName = :firstNameOfContact2 AND Contact.LastName = :lastNameOfContact2 LIMIT 1];
            } catch (Exception ex){
                System.debug('CATCH');
                
                //create a new case object
                Contact newCaseContact = new Contact();

                //fill in the first name
                newCaseContact.FirstName = firstNameOfContact2;  

                //fill in the last name
                newCaseContact.LastName = lastNameOfContact2;
                
                //insert the new contact into the database with the first and the last name
                insert newCaseContact; 
            
                //create a new case object
                Case emailToCase = new Case();

                //fill in the subject line of the case, in this case it's the name of the device and then the static string below
                emailToCase.Subject = nameOfLocation2 + ', has detected a leak!'; 

                //fill in the description of the case with all of the text from the email
                emailToCase.Description = myPlainText;

                //specify that the case was created from an email
                emailToCase.Origin = 'Email';

                //link the new contact to the new case
                emailToCase.ContactId = newCaseContact.id;

                //set the priority level to high because there is a water leak somewhere
                emailToCase.Priority = 'High';
    
                //insert the case into the database
                insert emailToCase;
                
                //set the result to true because the case was successfully created from the email
                result.success = true;
                
                //return the result and exit the program
                return result;
            }
            //create a new case object
            Contact newCaseContact = new Contact();
            
            //fill in the first name
            newCaseContact.FirstName = firstNameOfContact2;  
            
            //fill in the last name
            newCaseContact.LastName = lastNameOfContact2;
            
            //insert the new contact into the database with the first and the last name
            insert newCaseContact; 
            
            //create a new case object
            Case emailToCase = new Case();
            
            //fill in the subject line of the case, in this case it's the name of the device and then the static string below
            emailToCase.Subject = nameOfLocation2 + ', has detected a leak!'; 
            
            //fill in the description of the case with all of the text from the email
            emailToCase.Description = myPlainText;
            
            //specify that the case was created from an email
            emailToCase.Origin = 'Email';
            
            //link the new contact to the new case
            emailToCase.ContactId = newCaseContact.id;
            
            //set the priority level to high because there is a water leak somewhere
            emailToCase.Priority = 'High';
            
            //insert the case into the database
            insert emailToCase;
            
            //set the result to true because the case was successfully created from the email
            result.success = true;
            
            //return the result and exit the program
            return result;
    
        } else if ((myPlainText.contains('Lyric')) && myPlainText.contains('Honeywell') && myPlainText.contains('Resolved')) {

             //Do some hard coded parsing to pull the first name and last name out of the email
             //Check it against the existing contacts to see if the contact exists, otherwise make a new one.
         
            //Find the complete name of the contact
            String nameOfContact1 = myPlainText.substringBetween('The following user have access to', '.');  
            System.debug('nameOfContact1=' + nameOfContact1);
            String nameOfContact2 = nameOfContact1.substringAfter(':');
            System.debug('nameOfContact2=' + nameOfContact2);
            
            //Find the last name of the contact
            String lastNameOfContact1 = nameOfContact2.trim();
            System.debug('lastNameOfContact1=' + lastNameOfContact1);
            String lastNameOfContact2 = lastNameOfContact1.substringAfter(' ');
            System.debug('lastNameOfContact2=' + lastNameOfContact2);
            
            //Find the first name of the contact
            String firstNameOfContact1 =  nameOfContact2.substringBeforeLast(' ');
            System.debug('firstNameOfContact1=' + firstNameOfContact1);
            String firstNameOfContact2 =  firstNameOfContact1.trim();
            System.debug('firstNameOfContact2=' + firstNameOfContact2);
            
            //Find the name of the device
            String nameOfLocation1 = myPlainText;
            System.debug('nameOfLocation1=' + nameOfLocation1);
            String nameOfLocation2 = nameOfLocation1.substringBetween('have access to', 'location:').trim();
            System.debug('nameOfLocation2=' + nameOfLocation2);
            
            
            //create a new contact object
            Contact caseContact2;
            
            //code to find an existing contact
            try{
                System.debug('TRY');
                System.debug(firstNameOfContact2);
                System.debug(lastNameOfContact2);

                //SOQL query to find an existing contact in the database with the first and last name specified in the email
                caseContact2 = [SELECT Id FROM CONTACT WHERE Contact.FirstName = :firstNameOfContact2 AND Contact.LastName = :lastNameOfContact2 LIMIT 1];
            } catch (Exception ex){
                System.debug('CATCH');
                
                //create a new case object
                Contact newCaseContact = new Contact();

                //fill in the first name
                newCaseContact.FirstName = firstNameOfContact2;  

                //fill in the last name
                newCaseContact.LastName = lastNameOfContact2;
                
                //insert the new contact into the database with the first and the last name
                insert newCaseContact; 
            
                //create a new case object
                Case emailToCase = new Case();

                //fill in the subject line of the case, in this case it's the name of the device and then the static string below
                emailToCase.Subject = nameOfLocation2 + ', has had the issue resolved!'; 

                //fill in the description of the case with all of the text from the email
                emailToCase.Description = myPlainText;

                //specify that the case was created from an email
                emailToCase.Origin = 'Email';

                //link the new contact to the new case
                emailToCase.ContactId = newCaseContact.id;

                //set the priority level to high because there is a water leak somewhere
                emailToCase.Priority = 'Low';
    
                //insert the case into the database
                insert emailToCase;
                
                //set the result to true because the case was successfully created from the email
                result.success = true;
                
                //return the result and exit the program
                return result;
            }
        
            //create a new case object
            Case emailToCase = new Case();

            //fill in the subject line of the case, in this case it's the name of the device and then the static string below
            emailToCase.Subject = nameOfLocation2 + ', has had the leak issue resolved!'; 

            //fill in the description of the case with all of the text from the email
            emailToCase.Description = myPlainText;

            //specify that the case was created from an email
            emailToCase.Origin = 'Email';
            
            //link the existing contact to the new case
            emailToCase.ContactId = caseContact2.id;

            //set the priority level to high because there is a water leak somewhere
            emailToCase.Priority = 'Low';
            
            //insert the case into the database
            insert emailToCase;

        } else{
            //default constructor
            Case emailToCase = new Case();

            //fill out the subject of the email but make it apparent that it's the default constructor
            emailToCase.Subject = 'Default Parse: ' + email.subject;

            //copy the email text into the case description
            emailToCase.Description = myPlainText;

            //specify that the case was created from an email
            emailToCase.Origin = 'Email';

            //set the priority to low because it didn't fit any other criteria 
            emailToCase.Priority = 'Low';

            //inset the case into the database
            insert emailToCase;
        }

        // Set the result to true because the email was parsed correctly
        result.success = true;
        
        // Return the result for the Apex Email Service
        return result;
    }
}
