"use strict";

main();

/*    - - - - - - - - - - - - - - - - - - - - - - - - - -    */
/*
*    Chain of child->parent elements:
*       table cell -> table row -> table body -> table -> li -> ul
*/

function main()
  {
  let tds = document.getElementsByClassName("folder");
  for (let i=0; i<tds.length; i++)
    {
    tds[i].addEventListener('click', Toggle);
    }

  document.addEventListener('error', function(err)
    {
    alert(err);
    return;
    });

  let btnOpen = document.getElementById("btnOpen");
  btnOpen.addEventListener('click', function()
    {
    OpenAll();
    });

  let btnClose = document.getElementById("btnClose");
  btnClose.addEventListener('click', function()
    {
    CloseAll();
    });

  let btnAbout = document.getElementById("btnAbout");
  btnAbout.addEventListener('click', function()
    {
    let msg = 
       "Clicking on any folder image toggles the associated directory\n" +
       "between being in an open or closed state; on the other hand, a \n" + 
       "leaf indicates a directory which only contains files, and so does\n" +
       "not respond to clicking.  The associated size is equal to the sum\n" +
       "of the sizes, in bytes, of all the contained files, although the\n" +
       "size of linked files is set to 0.  Also, in the case of dos-type\n" +
       "operating systems, files having either a HIDDEN or SYSTEM\n" +
       "attribute are not included.\n\n" +
       "If the browser screen is initially blank, the root is a leaf, and\n" +
       "therefore in a closed state; simply click on the button labelled\n" +
       "'OPEN ALL' to see it.";
    alert(msg);
    });

  CloseAll();

  return;
  }
   
/*    - - - - - - - - - - - - - - - - - - - - - - - - - -    */

function OpenFolder(folder)
  {
  folder.setAttribute('state', 'open');
  let children = folder.parentElement.children;
  for (let i=1; i<children.length; i++)  // folder = children[0]
    {
    let child = children[i];
    if (child.tagName == 'LI')
      {
      child.style.display = 'block';
      let li = child.firstElementChild.firstElementChild;
      li.style.display = 'block';
      li.setAttribute('state', 'closed');
      }
    else
      {
      let err = "OpenFolder: child should be LI, not " + child.tagName;
      throw err;
      }
    }
  return;
  }
   
/*    - - - - - - - - - - - - - - - - - - - - - - - - - -    */

function CloseFolder(folder)
  {
  folder.setAttribute('state', 'closed');
  let children = folder.parentElement.children;
  for (let i=1; i<children.length; i++)  // folder = children[0]
    {
    let child = children[i];
    if (child.tagName == 'LI')
      {
      child.style.display = 'none';
      child.setAttribute('state', 'closed');
      }
    else
      {
      let err = "CloseFolder: child should be LI, not " + child.tagName;
      throw err;
      }
    }
  return;
  }

/*    - - - - - - - - - - - - - - - - - - - - - - - - - -    */

function CloseAll()
  {
  let arr = document.getElementsByTagName('LI');
  for (let i=0; i<arr.length; i++)
    {
    arr[i].setAttribute('state', 'closed');
    if (arr[i].id != 'root')
      {
      arr[i].style.display = 'none';
      }
    }
  return;
  }

/*    - - - - - - - - - - - - - - - - - - - - - - - - - -    */

function OpenAll()
  {
  let arr = document.getElementsByTagName('LI');
  for (let i=0; i<arr.length; i++)
    {
    arr[i].setAttribute('state', 'open');
    arr[i].style.display = 'block';
    }
  return;
  }

/*    - - - - - - - - - - - - - - - - - - - - - - - - - -    */

function Toggle(event)
  {
  let td = event.target;
  let li = td.parentElement.parentElement.parentElement.parentElement;
  let state = li.getAttribute('state');
  if (state == 'closed')
    {
    OpenFolder(li);
    }
  else
    {
    CloseFolder(li);
    }
  return;
  }

