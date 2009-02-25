Frequently Asked Questions
==========================
  The answer to every question is 'Read [The Documentation][1]'. However, for your convinience, the most common problem solutions are linked here.

Basics
------
*  **Why use Exherbo?**  
    If you like to know exactly what is going on with your system, you might like Exherbo. If you like to try new alternatives while still having a stable day-to-day system, you might like Exherbo.

How do I...
-----------

*  **...add new repositories?**  
    [ebuild and exheres Repository Formats][2]  
    Don't forget to prepend x- when syncing for the first time!

*  **...manage packages not in any repository?**  
    [``man importare``][3]  
    If you have the source untarred in some directory, and you already did ./configure && make, try the following.  
        # importare --install --location ~/code/foo-v0.3.4/ category/foo 0.3.4
	
*  **...work with binary packages?**  
    You are going to have to delve a bit into the source code, as this feature is not meant for end-users just yet.
    
*  **...start writing exheres?**  
    [Exheres for smarties](http://exherbo.org/docs/exheres-for-smarties.html#tree_layout)  

Package Masked Errors
---------------------

  It is a good idea to read all the error messages paludis outputs carefully, they are verbose for a reason and easy to understand.

``* All versions of 'category/package' are masked. Candidates are:``        

*  **Masked by unavailable**    
        * dev-perl/XML-Simple-2.18:0::unavailable (in ::perl): Masked by unavailable (In a repository which is unavailable)  
    Add the perl repository, see 'How do I add new repositories?' above.

*  **Masked by unwritten**  
        * net-fs/samba-3.0.32:0::unwritten: Masked by unwritten (Package has not been written yet)  
    This means the package hasn't been written, try 'paludis -q samba', then see 'How do I start writing exheres?' above.

*  **Masked by platform**  
        * sys-boot/grub-1.96:0::arbor: Masked by platform (~x86)  
    ``echo "sys-boot/grub ~x86" >> /etc/paludis/platforms.conf``

[1]: http://exherbo.org/documentation.html
[2]: http://paludis.pioto.org/configuration/repositories/e.html "exheres Repository Formats"
[3]: http://paludis.pioto.org/clients/importare.html "man importare"
