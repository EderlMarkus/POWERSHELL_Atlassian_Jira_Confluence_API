var medals = {
  1: "https://antrag.tst.raiffeisenbank.at/rest/fileStore/1fc43f4e-e5c0-446f-a43a-75a540ffe95c?companyBusinessId=COMPANY_BUSINESS_ID",
  2: "https://antrag.tst.raiffeisenbank.at/rest/fileStore/0a09c14c-9144-4f13-ab67-ff6f3210d55c?companyBusinessId=COMPANY_BUSINESS_ID",
  3: "https://antrag.tst.raiffeisenbank.at/rest/fileStore/6c02c8e6-a5db-4fde-9bc9-7f2133200c39?companyBusinessId=COMPANY_BUSINESS_ID",
};

const table = document.getElementsByClassName("table")[0];

dataJSON.forEach((element) => {
  const mytr = document.createElement("tr");
  const recipientTd = document.createElement("td");
  const medalTd = document.createElement("td");
  const topicTd = document.createElement("td");
  const dateTd = document.createElement("td");

  recipientTd.innerHTML = element.recepient;
  medalTd.innerHTML = `<img class='medal ${
    element.level == 1 ? "gold" : element.level == 2 ? "silber" : "bronze"
  }' src='${medals[element.level]}'/>`;
  topicTd.innerHTML = `Für: ${element.topic}`;
  dateTd.innerHTML = `${element.date}`;

  mytr.appendChild(recipientTd);
  mytr.appendChild(medalTd);
  mytr.appendChild(topicTd);
  mytr.appendChild(dateTd);

  table.appendChild(mytr);
});

function filter(input) {
  // Declare variables
  var input, filter, table, tr, td, i, txtValue;

  filter = input.toUpperCase();
  table = document.getElementsByClassName("table")[0];
  tr = table.getElementsByTagName("tr");

  // Loop through all table rows, and hide those who don't match the search query
  for (i = 0; i < tr.length; i++) {
    td = tr[i].getElementsByTagName("td")[window.cellIndex];

    if (td) {
      txtValue = td.textContent || td.innerHTML;
      if (txtValue.toUpperCase().indexOf(filter) > -1) {
        tr[i].style.display = "";
      } else {
        tr[i].style.display = "none";
      }
    }
  }
}

$("body").on("click", "[data-editable]", function () {
  debugger;
  var $el = $(this);
  window.cellIndex = $el[0].cellIndex;

  var $input = $("<th><input/></th>").val($el.text());
  $el.replaceWith($input);
  window.searchInput = $el.text();

  var save = function () {
    const ths = document.getElementsByTagName("th");
    for (let index = 0; index < ths.length; index++) {
      const th = ths[index];
      let text;
      if (window.cellIndex !== index) {
        switch (index) {
          case 0:
            th.innerText = "Empfänger";
            break;
          case 1:
            th.innerText = "Level";
            break;
          case 2:
            th.innerText = "Thema";
            break;
          case 3:
            th.innerText = "Verliehen am";
            break;
          default:
            break;
        }
      }
    }
    let text = $input.children().val()
      ? $input.children().val()
      : window.cellIndex == 0
      ? "Empfänger"
      : window.cellIndex == 1
      ? "Level"
      : window.cellIndex == 2
      ? "Thema"
      : "Verliehen am";

    var $p = $("<th data-editable />").text(text);
    $input.replaceWith($p);
    filter($input.children().val());
  };

  $input.children().one("blur", save).focus();
  $input
    .children()
    .on("keypress", (e) => {
      debugger;
      if (e.which == 13) {
        save();
      }
    })
    .focus();
});
