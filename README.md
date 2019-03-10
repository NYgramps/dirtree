In each of these repositories, there is either a *html* file, or executable code which creates one
(typically a *perl* script) when run at the command line.  Once downloaded, the user can bookmark such a file in a
browser for use as a utility.  All of these *html* files are supported by plain vanilla *javascript* and *css*.

**_webcal_** displays an annual calandar for the year interactively input by the user;
the current day of the current year is highlighted.

**_ccrate_** provides a *html* file which serves as an interface to collect some input data from the user.
A time interval is specified by input, over which the **continuously compounded rate** is computed for an
underlying financial account.  The account's transaction history is stored in a **csv** file, making for easy editing
by the user via any modern spreadsheet program.  The transactions contained in the **csv** file, and the
values computed by the algorithm which converge to the answer, can be viewed in the web console of the
browser; in addition, a *perl* script, **_ccrate.pl_**, is provided for interested parties,
such as developers, which performs the same calculation.

**_dirtree_** contains two analogous _perl_ scripts, one for _unix_-like systems, **_dirtree_unix.pl_**,
and the other, **_dirtree_dos.pl_**, for _windows_.  Each generates a _html_ file which displays a
**collapsible tree** of subdirectories, with associated sizes, for manipulation by the user
to easily visualize disc usage.
